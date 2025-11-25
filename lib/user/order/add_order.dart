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
  List<Map<String, dynamic>> meals = [];
  bool isLoadingMeals = true;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
    _fetchMeals();
  }

  Future<void> _fetchUserId() async {
    if (widget.username == null || widget.username!.isEmpty) return;

    var url = Uri.parse("${globals.baseUrl}get_user_id.php");

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": widget.username}),
      );

      if (response.headers['content-type']!.contains('application/json')) {
        var data = jsonDecode(response.body);
        if (data["success"]) {
          setState(() => userId = data["user_id"].toString());
        }
      }
    } catch (e) {
      print("Erreur userId : $e");
    }
  }

  Future<void> _fetchMeals() async {
    var url = Uri.parse("${globals.baseUrl}list_meals.php");
    try {
      var response = await http.get(url);

      if (response.headers['content-type']!.contains('application/json')) {
        var data = jsonDecode(response.body);
        if (data["success"]) {
          setState(() {
            meals = List<Map<String, dynamic>>.from(data["meals"]);
            isLoadingMeals = false;
          });
        }
      }
    } catch (e) {
      isLoadingMeals = false;
    }
  }

  Future<void> _passerCommandeUnique(String mealId, String mealName) async {
    int? quantity = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int tempQuantity = 1;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Commander $mealName',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle,
                      color: Colors.red,
                      size: 32,
                    ),
                    onPressed: () {
                      if (tempQuantity > 1) setState(() => tempQuantity--);
                    },
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tempQuantity.toString(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.green, size: 32),
                    onPressed: () => setState(() => tempQuantity++),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: Text("Annuler"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.shopping_cart),
              label: Text("Commander"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, tempQuantity),
            ),
          ],
        );
      },
    );

    if (quantity != null && quantity > 0) {
      var url = Uri.parse("${globals.baseUrl}add_orders.php");

      try {
        var response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": userId,
            "commandes": [
              {"meal_id": mealId, "quantity": quantity},
            ],
            "status": "pending",
          }),
        );

        if (jsonDecode(response.body)["success"]) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Commande de $quantity x $mealName effectuée !"),
              backgroundColor: Colors.green,
            ),
          );
          widget.onOrderAdded();
        }
      } catch (e) {
        print("Erreur commande unique: $e");
      }
    }
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty)
      return "${globals.baseUrl}images/default_meal.jpg";

    if (imagePath.startsWith('http')) return imagePath;

    if (imagePath.contains("uploads/")) {
      return "${globals.baseUrl}$imagePath";
    } else {
      return "${globals.baseUrl}uploads/$imagePath";
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
          "Ajouter une commande",
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined, color: Colors.green),
            iconSize: 28,
            onPressed: () {
              Navigator.pushNamed(context, "/list_orders");
            },
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 20),

            Expanded(
              child:
                  isLoadingMeals
                      ? Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      )
                      : ListView.builder(
                        itemCount: meals.length,
                        itemBuilder: (context, index) {
                          final meal = meals[index];
                          final price =
                              double.tryParse(meal["price"].toString()) ?? 0.0;

                          return Container(
                            margin: EdgeInsets.only(bottom: 14),
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
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(18),
                                  ),
                                  child: Image.network(
                                    _getImageUrl(meal["image"]),
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),

                                Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        meal["name"],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      SizedBox(height: 4),
                                      Text(
                                        "€${price.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[700],
                                        ),
                                      ),

                                      SizedBox(height: 10),

                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              () => _passerCommandeUnique(
                                                meal["id"].toString(),
                                                meal["name"],
                                              ),
                                          icon: Icon(Icons.shopping_cart),
                                          label: Text("Commander"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
