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
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredMeals = [];

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
            filteredMeals = List.from(meals);
            isLoadingMeals = false;
          });
        }
      }
    } catch (e) {
      isLoadingMeals = false;
    }
  }

  void _filterMeals(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMeals = List.from(meals);
      } else {
        filteredMeals =
            meals.where((meal) {
              final name = meal["name"].toString().toLowerCase();
              return name.contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  Future<void> _showMealDetails(Map<String, dynamic> meal) async {
    final price = double.tryParse(meal["price"].toString()) ?? 0.0;
    int quantity = 1;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final totalPrice = price * quantity;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Header with close button
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          "Food Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // Meal image
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        _getImageUrl(meal["image"]),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2CB14A),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.fastfood,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Meal name and price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    meal["name"],
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  "${price.toStringAsFixed(2)} DT",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2CB14A),
                                  ),
                                ),
                              ],
                            ),
                           

                            SizedBox(height: 24),

                            // About food section
                         

                            SizedBox(height: 8),

                            Text(
                              meal["description"] ?? "No description available.",
                              style: TextStyle(
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                            ),

                            SizedBox(height: 24),

                            // Total price display
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total:",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "${totalPrice.toStringAsFixed(2)} DT",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2CB14A),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Quantity selector and order button
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Quantity selector
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.remove,
                                            color: Color(0xFF2CB14A),
                                          ),
                                          onPressed: () {
                                            if (quantity > 1) {
                                              setState(() => quantity--);
                                            }
                                          },
                                        ),
                                        Container(
                                          width: 50,
                                          alignment: Alignment.center,
                                          child: Text(
                                            quantity.toString(),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.add,
                                            color: Color(0xFF2CB14A),
                                          ),
                                          onPressed: () {
                                            setState(() => quantity++);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Order button
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _passerCommandeUnique(
                                        meal["id"].toString(),
                                        meal["name"],
                                        quantity,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF2CB14A),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.shopping_bag_outlined),
                                        SizedBox(width: 8),
                                        Text(
                                          "Add to cart",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _passerCommandeUnique(
    String mealId,
    String mealName,
    int quantity,
  ) async {
    if (quantity <= 0) return;

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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        widget.onOrderAdded();
      }
    } catch (e) {
      print("Erreur commande unique: $e");
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

  Widget _buildCategoryChip(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Color(0xFF2CB14A)),
          SizedBox(width: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom AppBar
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[100],
                        ),
                        child: Icon(Icons.arrow_back, color: Colors.grey[700]),
                      ),
                    ),
                    Text(
                      "Ajouter une commande",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, "/list_orders");
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[100],
                        ),
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          color: Color(0xFF2CB14A),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: _filterMeals,
                    decoration: InputDecoration(
                      hintText: "Search Food...",
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      suffixIcon:
                          searchController.text.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey[500],
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  _filterMeals("");
                                },
                              )
                              : null,
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Categories
              ],
            ),
          ),

          // Meals grid
          Expanded(
            child:
                isLoadingMeals
                    ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2CB14A),
                      ),
                    )
                    : filteredMeals.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fastfood_outlined,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Aucun plat trouvé",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                    : GridView.builder(
                      padding: EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: filteredMeals.length,
                      itemBuilder: (context, index) {
                        final meal = filteredMeals[index];
                        final price =
                            double.tryParse(meal["price"].toString()) ?? 0.0;

                        return GestureDetector(
                          onTap: () => _showMealDetails(meal),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Meal image
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                    child: Image.network(
                                      _getImageUrl(meal["image"]),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      loadingBuilder: (
                                        context,
                                        child,
                                        loadingProgress,
                                      ) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF2CB14A),
                                            strokeWidth: 2,
                                          ),
                                        );
                                      },
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: Icon(
                                              Icons.fastfood,
                                              size: 40,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        maxLines: 1,
                                      ),

                                      SizedBox(height: 4),

                                      Text(
                                        meal["description"] ?? "",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        maxLines: 2,
                                      ),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "${price.toStringAsFixed(2)} DT",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2CB14A),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _showMealDetails(meal),
                                            child: Container(
                                              padding: EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF2CB14A),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.add,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
