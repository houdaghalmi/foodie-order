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
    print("ListOrders initialisé avec username: ${widget.username}");
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserId();
    });
  }

  Future<void> _fetchUserId() async {
    if (widget.username == null) {
      print("Username est null, pas de récupération d'ID utilisateur");
      _fetchOrders();
      return;
    }

    print("Récupération de l'ID pour l'utilisateur: ${widget.username}");
    
    var url = Uri.parse("${globals.baseUrl}get_user_id.php");
    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": widget.username}),
      );

      print("Réponse du serveur: ${response.statusCode}");
      print("Contenu de la réponse: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print("Données décodées: $data");
        
        if (data["success"] == true) {
          setState(() {
            userId = data["user_id"].toString();
          });
          print("ID utilisateur récupéré: $userId");
        } else {
          print("Échec de récupération: ${data['message']}");
        }
      } else {
        print("Erreur HTTP: ${response.statusCode}");
      }
    } catch (e) {
      print("Erreur lors de la récupération de l'ID utilisateur: $e");
    } finally {
      _fetchOrders();
    }
  }

  Future<bool> _ensureUserId() async {
    if (userId != null) {
      print("userId déjà disponible: $userId");
      return true;
    }
    
    if (widget.username == null) {
      print("Username est null, impossible de récupérer l'ID");
      return false;
    }

    print("Tentative de récupération de l'ID utilisateur...");
    
    await _fetchUserId();
    await Future.delayed(Duration(milliseconds: 100));
    
    if (userId == null) {
      print("Échec: userId toujours null après récupération");
      return false;
    }
    
    print("Succès: userId = $userId");
    return true;
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });

    var url = Uri.parse("${globals.baseUrl}list_orders.php");

    try {
      var response;
      if (userId != null) {
        print("Récupération des commandes pour userId: $userId");
        response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"user_id": userId}),
        );
      } else {
        print("Récupération de toutes les commandes (userId null)");
        response = await http.get(url);
      }

      print("Status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        var contentType = response.headers['content-type']?.toLowerCase() ?? '';
        if (contentType.contains('application/json')) {
          var data = json.decode(response.body);
          var orders = data['orders'] ?? [];

          print("${orders.length} commandes reçues");

          // Double vérification côté client
          if (userId != null) {
            orders = orders
                .where((order) => order['user_id'].toString() == userId)
                .toList();
            print("${orders.length} commandes filtrées pour userId: $userId");
          }

          setState(() {
            _orders = orders;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          print("Réponse non JSON: ${response.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur: réponse serveur invalide")),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur serveur (${response.statusCode})")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Erreur réseau: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau ou serveur indisponible")),
      );
    }
  }

  void _navigateToAddOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddOrderForm(
          onOrderAdded: () {
            Navigator.pop(context);
            _fetchOrders();
          },
          username: widget.username,
        ),
      ),
    );
  }

  void _editOrder(int id) {
    var order = _orders.firstWhere((o) => o["id"] == id);
    
    // VÉRIFIER SI L'UTILISATEUR EST CONNECTÉ
    if (widget.username == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur: Vous devez être connecté pour modifier une commande"),
        ),
      );
      return;
    }
    
    // VÉRIFIER SI L'UTILISATEUR EST LE PROPRIÉTAIRE DE LA COMMANDE
    if (userId != null && order['user_id'].toString() != userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur: Vous ne pouvez modifier que vos propres commandes"),
        ),
      );
      return;
    }

    if (order['status'] == 'pending') {
      _showStatusDialog(id);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EditOrderForm(order: order, onOrderUpdated: _fetchOrders),
        ),
      );
    }
  }

  void _showStatusDialog(int orderId) {
    var order = _orders.firstWhere((o) => o["id"] == orderId);
    
    // Vérifier l'appartenance de la commande
    if (userId != null && order['user_id'].toString() != userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur: Vous ne pouvez modifier que vos propres commandes"),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Modifier le statut",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Cette commande est en attente. Choisissez une action:",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateOrderStatus(orderId, 'confirmed');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: BorderSide(color: Colors.green),
                    ),
                    child: Text("Confirmer"),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateOrderStatus(orderId, 'cancelled');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                    ),
                    child: Text("Annuler"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateOrderStatus(int orderId, String newStatus) async {
    var order = _orders.firstWhere((o) => o["id"] == orderId);
    
    // Vérifier l'appartenance
    if (userId != null && order['user_id'].toString() != userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur: Vous ne pouvez modifier que vos propres commandes"),
        ),
      );
      return;
    }

    if (newStatus == 'confirmed') {
      _showConfirmForm(order);
    } else {
      _updateOrder(orderId, {...order, 'status': newStatus});
    }
  }

  void _showConfirmForm(Map<String, dynamic> order) async {
    if (widget.username == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur: Utilisateur non connecté"),
        ),
      );
      return;
    }

    final userIdentified = await _ensureUserId();
    if (!userIdentified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'identifier l'utilisateur. Veuillez réessayer."),
        ),
      );
      return;
    }

    TextEditingController telController = TextEditingController();
    TextEditingController adresseController = TextEditingController();

    // Pré-remplir si déjà existant
    if (order['tel'] != null) {
      telController.text = order['tel'].toString();
    }
    if (order['adresse'] != null) {
      adresseController.text = order['adresse'].toString();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Confirmer la commande",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Veuillez compléter vos informations de livraison",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),

                  // Téléphone field
                  TextField(
                    controller: telController,
                    decoration: InputDecoration(
                      labelText: "Téléphone*",
                      hintText: "Ex: 12 345 678",
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

                  SizedBox(height: 15),

                  // Adresse field
                  TextField(
                    controller: adresseController,
                    decoration: InputDecoration(
                      labelText: "Adresse de livraison*",
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    maxLines: 2,
                  ),

                  SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Annuler"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (telController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Veuillez saisir un numéro de téléphone"),
                              ),
                            );
                            return;
                          }

                          if (adresseController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Veuillez saisir une adresse"),
                              ),
                            );
                            return;
                          }

                          bool success = await _updateOrderadresse(
                            order['id'],
                            telController.text.trim(),
                            adresseController.text.trim(),
                          );

                          if (success) {
                            await _updateOrder(order['id'], {
                              ...order,
                              'status': 'confirmed',
                              'tel': telController.text.trim(),
                              'adresse': adresseController.text.trim(),
                            });

                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text("Confirmer"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _updateOrderadresse(int orderId, String tel, String adresse) async {
    print("Mise à jour de l'adresse pour la commande ID: $orderId");
    print("Téléphone: $tel");
    print("Adresse: $adresse");

    final url = Uri.parse("${globals.baseUrl}update_order_info.php");
    try {
      final response = await http.post(
        url,
        headers: const {"Content-Type": "application/json"},
        body: jsonEncode({
          "order_id": orderId,
          "tel": tel,
          "adresse": adresse,
        }),
      );

      print("Réponse de update_order_adresse.php: ${response.statusCode}");
      print("Contenu: ${response.body}");

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur serveur (${response.statusCode})")),
        );
        return false;
      }

      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      if (!contentType.contains('application/json')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Format de réponse invalide")),
        );
        return false;
      }

      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Adresse mise à jour avec succès")),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Échec de la mise à jour")),
        );
        return false;
      }
    } catch (e) {
      print("Erreur réseau dans _updateOrderadresse: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion: $e")),
      );
      return false;
    }
  }

  Future<void> _updateOrder(
    int orderId,
    Map<String, dynamic> updatedData,
  ) async {
    var url = Uri.parse("${globals.baseUrl}edit_order.php");

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": orderId,
          "quantity": updatedData['quantity'],
          "total_price": updatedData['total_price'],
          "status": updatedData['status'],
          "adresse": updatedData['adresse'],
          "user_id": userId, // AJOUT POUR LA VÉRIFICATION SERVEUR
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["success"]) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Commande ${updatedData['status'] == 'confirmed' ? 'confirmée' : 'annulée'}",
              ),
            ),
          );
          _fetchOrders();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur: ${data['message']}")),
          );
        }
      }
    } catch (e) {
      print("Erreur dans _updateOrder: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la mise à jour")),
      );
    }
  }

  Future<void> _deleteOrder(int id) async {
    // Vérifier l'appartenance avant suppression
    var order = _orders.firstWhere((o) => o["id"] == id, orElse: () => {});
    
    if (order.isNotEmpty && userId != null && order['user_id'].toString() != userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur: Vous ne pouvez supprimer que vos propres commandes"),
        ),
      );
      return;
    }

    var url = Uri.parse("${globals.baseUrl}delete_order.php?id=$id&user_id=$userId");

    try {
      var response = await http.post(url);

      if (response.statusCode == 200) {
        var contentType = response.headers['content-type']?.toLowerCase() ?? '';
        if (contentType.contains('application/json')) {
          var data = jsonDecode(response.body);
          if (data["success"]) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Commande supprimée")),
            );
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur serveur (${response.statusCode})")),
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
          if (widget.username != null) // Afficher seulement si connecté
            IconButton(
              icon: Icon(Icons.add_shopping_cart, color: Colors.green, size: 28),
              onPressed: _navigateToAddOrder,
              tooltip: "Nouvelle commande",
            ),
        ],
      ),
      body: _isLoading
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
                        widget.username != null 
                          ? "Aucune commande" 
                          : "Connectez-vous pour voir vos commandes",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.username != null
                          ? "Commencez à commander vos repas préférés"
                          : "Veuillez vous connecter pour accéder à vos commandes",
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
                                  Expanded(
                                    child: Text(
                                      order['meal_name'] ?? "Nom du repas",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 10),
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
                              // Afficher l'adresse si elle existe
                              if (order['adresse'] != null && order['adresse'].isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 20,
                                          color: Colors.blue[600],
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Adresse: ${order['adresse']}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                  ],
                                ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.fastfood,
                                    size: 20,
                                    color: Colors.green[600],
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Repas: ${order['meal_name'] ?? 'ID: ${order['meal_id']}'}",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey[700],
                                      ),
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
                                    "${order['total_price']} DT",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              if (widget.username != null) // Afficher les boutons seulement si connecté
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (order['status'] != 'cancelled')
                                      IconButton(
                                        onPressed: () => _editOrder(order['id']),
                                        icon: Icon(Icons.edit, size: 22),
                                        color: Colors.blue,
                                        tooltip: "Modifier",
                                      ),
                                    IconButton(
                                      onPressed: () => _deleteOrder(order['id']),
                                      icon: Icon(Icons.delete, size: 22),
                                      color: Colors.red,
                                      tooltip: "Supprimer",
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