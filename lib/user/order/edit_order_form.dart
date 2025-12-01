import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:foodie_order/globals.dart' as globals;

class EditOrderForm extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onOrderUpdated;

  const EditOrderForm({
    Key? key,
    required this.order,
    required this.onOrderUpdated,
  }) : super(key: key);

  @override
  State<EditOrderForm> createState() => _EditOrderFormState();
}

class _EditOrderFormState extends State<EditOrderForm> {
  late TextEditingController quantityController;
  late String status;
  late double mealPrice;
  late double totalPrice;

  @override
  void initState() {
    super.initState();
    quantityController = TextEditingController(
      text: widget.order['quantity'].toString(),
    );
    status = widget.order['status'];
    mealPrice =
        double.tryParse(widget.order['meal_price']?.toString() ?? '') ?? 0.0;
    totalPrice =
        double.tryParse(widget.order['total_price']?.toString() ?? '') ?? 0.0;

    int initialQty =
        int.tryParse(widget.order['quantity']?.toString() ?? '') ?? 1;
    if ((mealPrice <= 0.0) && (totalPrice > 0.0) && (initialQty > 0)) {
      mealPrice = totalPrice / initialQty;
    }
  }

  void _updateTotalPrice() {
    int qty = int.tryParse(quantityController.text) ?? 1;
    if (mealPrice <= 0.0 && totalPrice > 0 && qty > 0) {
      mealPrice = totalPrice / qty;
    }
    setState(() {
      totalPrice = mealPrice * qty;
    });
  }

  Future<void> _submit() async {
    int? qty = int.tryParse(quantityController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez saisir une quantité valide")),
      );
      return;
    }

    var url = Uri.parse("${globals.baseUrl}edit_order.php");
    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": widget.order['id'],
          "quantity": qty,
          "total_price": double.parse(totalPrice.toStringAsFixed(2)),
          "status": status,
        }),
      );

      if (response.statusCode == 200 &&
          (response.headers['content-type']?.toLowerCase().contains(
                'application/json',
              ) ??
              false)) {
        var data = jsonDecode(response.body);
        if (data["success"]) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Commande modifiée avec succès")),
          );
          widget.onOrderUpdated();
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur : ${data['message']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur serveur ou réponse non JSON")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur réseau : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Modifier la commande",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20),

              // Quantity field
              Text(
                "Quantité",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Entrez la quantité",
                  prefixIcon: Icon(Icons.shopping_basket, color: Colors.green),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                onChanged: (_) => _updateTotalPrice(),
              ),
              SizedBox(height: 20),

              // Status dropdown
              Text(
                "Statut",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: status,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.info_outline, color: Colors.green),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: "pending",
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text("En attente"),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "confirmed",
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text("Confirmée"),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "cancelled",
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text("Annulée"),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    status = value ?? status;
                  });
                },
              ),
              SizedBox(height: 24),

              // Price display
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Prix total",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      "€${totalPrice.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Annuler",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Enregistrer",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
