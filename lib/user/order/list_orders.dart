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

      if (response.headers['content-type']?.toLowerCase().contains('application/json') ?? false) {
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
          (response.headers['content-type']?.toLowerCase().contains('application/json') ?? false)) {
        var data = json.decode(response.body);
        var orders = data['orders'] ?? [];

        if (userId != null) {
          orders = orders.where((order) => order['user_id'].toString() == userId).toList();
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
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Ajouter Commande", style: TextStyle(fontWeight: FontWeight.bold)),
        content: AddOrderForm(onOrderAdded: _fetchOrders),
      ),
    );
  }

  void _editOrder(int id) {
    var order = _orders.firstWhere((o) => o["id"] == id);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Modifier Commande", style: TextStyle(fontWeight: FontWeight.bold)),
        content: EditOrderForm(order: order, onOrderUpdated: _fetchOrders),
      ),
    );
  }

  Future<void> _deleteOrder(int id) async {
    var url = Uri.parse("${globals.baseUrl}delete_order.php?id=$id");

    try {
      var response = await http.post(url);

      if (response.statusCode == 200 &&
          (response.headers['content-type']?.toLowerCase().contains('application/json') ?? false)) {
        var data = jsonDecode(response.body);
        if (data["success"]) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Commande supprimée")));
          _fetchOrders();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur suppression: ${data['error'] ?? data['message']}")),
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
      backgroundColor: Color(0xfff5f6fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.username != null
              ? "Mes commandes (${widget.username})"
              : "Liste des commandes",
          style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.green[700]),
            onPressed: _showAddDialog,
            tooltip: "Ajouter commande",
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.green))
          : _orders.isEmpty
              ? Center(
                  child: Text(
                    "Aucune commande trouvée",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      var order = _orders[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        shadowColor: Colors.black12,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(
                            "Commande #${order['id']}",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Utilisateur: ${order['user_id']}",
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                                Text(
                                  "Repas: ${order['meal_id']}",
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Quantité: ${order['quantity']}  |  Prix total: ${order['total_price']} €",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      "Statut : ",
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(order['status']).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        order['status'].toString().toUpperCase(),
                                        style: TextStyle(
                                          color: _statusColor(order['status']),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                tooltip: "Modifier",
                                onPressed: () => _editOrder(order['id']),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                tooltip: "Supprimer",
                                onPressed: () => _deleteOrder(order['id']),
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
