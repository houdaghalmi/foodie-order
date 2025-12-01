import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:foodie_order/globals.dart' as globals;

import 'add_order.dart';
import 'edit_order_form.dart';

class ListOrders extends StatefulWidget {
  final String? username;

  const ListOrders({this.username, Key? key}) : super(key: key);

  @override
  _ListOrdersState createState() => _ListOrdersState();
}

class _ListOrdersState extends State<ListOrders> {
  List<dynamic> _orders = [];
  bool _isLoading = false;
  String? userId;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  Future<void> _fetchUserId() async {
    if (widget.username == null) {
      _fetchOrders();
      return;
    }

    var url = Uri.parse("${globals.baseUrl}get_user_id.php");
    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": widget.username}),
      );

      if (response.headers['content-type']?.toLowerCase().contains(
            'application/json',
          ) ??
          false) {
        var data = jsonDecode(response.body);
        if (data["success"]) {
          setState(() {
            userId = data["user_id"].toString();
          });
          _fetchOrders();
        } else {
          _fetchOrders();
        }
      } else {
        _fetchOrders();
      }
    } catch (e) {
      _fetchOrders();
    }
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });

    var url = Uri.parse("${globals.baseUrl}list_orders.php");

    try {
      var response;
      if (userId != null) {
        response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"user_id": userId}),
        );
      } else {
        response = await http.get(url);
      }

      if (response.statusCode == 200 &&
          (response.headers['content-type']?.toLowerCase().contains(
                'application/json',
              ) ??
              false)) {
        var data = json.decode(response.body);
        var orders = data['orders'] ?? [];

        if (userId != null) {
          orders =
              orders
                  .where((order) => order['user_id'].toString() == userId)
                  .toList();
        }

        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur serveur ou réponse non JSON")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau ou serveur indisponible")),
      );
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Ajouter Commande",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: AddOrderForm(onOrderAdded: _fetchOrders),
          ),
    );
  }

  void _editOrder(int id) {
    var order = _orders.firstWhere((o) => o["id"] == id);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Modifier Commande",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: EditOrderForm(order: order, onOrderUpdated: _fetchOrders),
          ),
    );
  }

  Future<void> _deleteOrder(int id) async {
    var url = Uri.parse("${globals.baseUrl}delete_order.php?id=$id");

    try {
      var response = await http.post(url);

      if (response.statusCode == 200 &&
          (response.headers['content-type']?.toLowerCase().contains(
                'application/json',
              ) ??
              false)) {
        var data = jsonDecode(response.body);
        if (data["success"]) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Commande supprimée")));
          _fetchOrders();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Erreur suppression: ${data['error'] ?? data['message']}",
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur serveur lors de la suppression")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau lors de la suppression.")),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "confirmed":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff9f9f9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black12,
        title: Text(
          widget.username != null ? "Mes commandes" : "Liste des commandes",
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_shopping_cart, color: Colors.green, size: 28),
            onPressed: _showAddDialog,
            tooltip: "Nouvelle commande",
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.green))
              : _orders.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Aucune commande",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Commencez à commander vos repas préférés",
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchOrders,
                color: Colors.green,
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    var order = _orders[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Commande #${order['id']}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      order['status'],
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _statusColor(
                                        order['status'],
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    order['status'].toString().toUpperCase(),
                                    style: TextStyle(
                                      color: _statusColor(order['status']),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Divider(height: 1),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.fastfood,
                                  size: 20,
                                  color: Colors.green[600],
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Repas ID: ${order['meal_id']}",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.shopping_basket,
                                  size: 20,
                                  color: Colors.green[600],
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Quantité: ${order['quantity']}",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  "€${order['total_price']}",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _editOrder(order['id']),
                                  icon: Icon(Icons.edit, size: 18),
                                  label: Text("Modifier"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: BorderSide(color: Colors.blue),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _deleteOrder(order['id']),
                                  icon: Icon(Icons.delete, size: 18),
                                  label: Text("Supprimer"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
