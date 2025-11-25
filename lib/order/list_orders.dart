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

      var data = jsonDecode(response.body);
      if (data["success"]) {
        setState(() {
          userId = data["user_id"].toString();
        });
        _fetchOrders();
      } else {
        _fetchOrders();
      }
    } catch (e) {
      print("Erreur lors de la récupération de l'ID utilisateur: $e");
      _fetchOrders();
    }
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });

    var url = Uri.parse("${globals.baseUrl}list_orders.php");
    print("Fetching orders from: $url");

    try {
      var response;
      if (userId != null) {
        // Fetch orders for specific user
        response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"user_id": userId}),
        );
      } else {
        // Fetch all orders
        response = await http.get(url);
      }
      print("Status code: ${response.statusCode}");
      print("Headers: ${response.headers}");
      print("Body: ${response.body}");

      if (response.statusCode == 200 &&
          (response.headers['content-type']?.toLowerCase().contains(
                'application/json',
              ) ??
              false)) {
        var data = json.decode(response.body);
        print("Decoded data: $data");

        var orders = data['orders'] ?? [];

        // Filter orders by user_id if userId is set
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
          SnackBar(content: Text("Réponse non JSON ou erreur serveur")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Exception during fetchOrders: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau ou serveur indisponible.")),
      );
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Ajouter Commande"),
          content: AddOrderForm(onOrderAdded: _fetchOrders),
        );
      },
    );
  }

  void _editOrder(int id) {
    var order = _orders.firstWhere((o) => o["id"] == id);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Modifier Commande"),
          content: EditOrderForm(order: order, onOrderUpdated: _fetchOrders),
        );
      },
    );
  }

  Future<void> _deleteOrder(int id) async {
    var url = Uri.parse("${globals.baseUrl}delete_order.php");

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["success"]) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Commande supprimée")));
          _fetchOrders();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erreur suppression")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur serveur lors de la suppression")),
        );
      }
    } catch (e) {
      print("Exception during deleteOrder: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau lors de la suppression.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.username != null
              ? "Mes commandes (${widget.username})"
              : "Liste des commandes",
        ),
        actions: [IconButton(icon: Icon(Icons.add), onPressed: _showAddDialog)],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _orders.isEmpty
              ? Center(child: Text("Aucune commande"))
              : ListView.builder(
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  var order = _orders[index];

                  return Card(
                    margin: EdgeInsets.all(12),
                    child: ListTile(
                      title: Text("Commande #${order['id']}"),
                      subtitle: Text(
                        "User: ${order['user_id']} | Meal: ${order['meal_id']}\n"
                        "Qte: ${order['quantity']} | Prix: ${order['total_price']} €\n"
                        "Status: ${order['status']}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editOrder(order['id']),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteOrder(order['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
