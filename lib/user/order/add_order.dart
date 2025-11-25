import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:foodie_order/globals.dart' as globals;

class AddOrderForm extends StatefulWidget {
  final Function onOrderAdded;
  final String? username;

  const AddOrderForm({required this.onOrderAdded, this.username, Key? key})
    : super(key: key);

  @override
  _AddOrderFormState createState() => _AddOrderFormState();
}

class _AddOrderFormState extends State<AddOrderForm> {
  String? userId;
  String? selectedMealId;
  List<Map<String, dynamic>> meals = [];
  bool isLoadingMeals = true;
  final TextEditingController quantityController = TextEditingController(
    text: "1",
  );
  String status = "pending";

  @override
  void initState() {
    super.initState();
    _fetchUserId();
    _fetchMeals();
  }

  Future<void> _fetchUserId() async {
    print("USERNAME REÇU = ${widget.username}");

    if (widget.username == null || widget.username!.isEmpty) {
      print("Username NULL → impossible de récupérer user_id");
      return;
    }

    var url = Uri.parse("${globals.baseUrl}get_user_id.php");

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": widget.username}),
      );

      print("Réponse API: ${response.body}");

      if (response.headers['content-type']?.toLowerCase().contains(
            'application/json',
          ) ??
          false) {
        var data = jsonDecode(response.body);
        if (data["success"]) {
          setState(() {
            userId = data["user_id"].toString();
          });
          print("User ID récupéré : $userId");
        } else {
          print(
            "Erreur récupération user_id : ${data["message"] ?? "inconnue"}",
          );
        }
      } else {
        print("Réponse non-JSON reçue de get_user_id.php: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: le serveur n'a pas retourné du JSON"),
          ),
        );
      }
    } catch (e) {
      print("Exception lors de _fetchUserId: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur réseau: $e")));
    }
  }

  Future<void> _fetchMeals() async {
    var url = Uri.parse("${globals.baseUrl}list_meals.php");
    try {
      var response = await http.get(url);

      print("Response from list_meals.php: ${response.body}");

      if (response.headers['content-type']?.toLowerCase().contains(
            'application/json',
          ) ??
          false) {
        var data = jsonDecode(response.body);
        print(data); // DEBUG

        if (data["success"]) {
          setState(() {
            meals = List<Map<String, dynamic>>.from(data["meals"]);
            isLoadingMeals = false;
          });
        } else {
          setState(() => isLoadingMeals = false);
          print("API error: ${data['message']}");
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erreur: ${data['message']}")));
        }
      } else {
        setState(() => isLoadingMeals = false);
        print("Réponse non-JSON reçue de list_meals.php: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: le serveur n'a pas retourné du JSON"),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoadingMeals = false);
      print("Erreur repas: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur réseau: $e")));
    }
  }

  Future<void> _addOrder() async {
    var url = Uri.parse("${globals.baseUrl}add_orders.php");

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "meal_id": selectedMealId,
          "quantity": quantityController.text,
          "status": status,
        }),
      );

      print("Response from add_orders.php: ${response.body}");

      if (response.headers['content-type']?.toLowerCase().contains(
            'application/json',
          ) ??
          false) {
        var data = jsonDecode(response.body);

        if (data["success"]) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Commande ajoutée avec succès !")),
          );
          widget.onOrderAdded();
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur : ${data["message"]}")),
          );
        }
      } else {
        print("Réponse non-JSON reçue: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur serveur: réponse non-JSON")),
        );
      }
    } catch (e) {
      print("Exception lors de _addOrder: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur réseau : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajouter une commande")),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Utilisateur: ${widget.username ?? 'Non connecté'}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              isLoadingMeals
                  ? CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                    value: selectedMealId,
                    decoration: InputDecoration(labelText: "Repas"),
                    items:
                        meals.map((meal) {
                          return DropdownMenuItem<String>(
                            value: meal["id"].toString(),
                            child: Text(meal["name"]),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMealId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return "Veuillez sélectionner un repas";
                      }
                      return null;
                    },
                  ),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: "Quantité"),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField(
                value: status,
                decoration: InputDecoration(labelText: "Statut"),
                items: [
                  DropdownMenuItem(value: "pending", child: Text("Pending")),
                  DropdownMenuItem(
                    value: "confirmed",
                    child: Text("Confirmed"),
                  ),
                  DropdownMenuItem(
                    value: "cancelled",
                    child: Text("Cancelled"),
                  ),
                ],
                onChanged: (value) => setState(() => status = value.toString()),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addOrder,
                child: Text("Ajouter la commande"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
