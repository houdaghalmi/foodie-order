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
    quantityController = TextEditingController(text: widget.order['quantity'].toString());
    status = widget.order['status'];
    mealPrice = double.tryParse(widget.order['meal_price']?.toString() ?? '') ?? 0.0;
    totalPrice = double.tryParse(widget.order['total_price']?.toString() ?? '') ?? 0.0;

    int initialQty = int.tryParse(widget.order['quantity']?.toString() ?? '') ?? 1;
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
          (response.headers['content-type']?.toLowerCase().contains('application/json') ?? false)) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Quantité",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (_) => _updateTotalPrice(),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: status,
              decoration: InputDecoration(
                labelText: "Statut",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: [
                DropdownMenuItem(value: "pending", child: Text("Pending")),
                DropdownMenuItem(value: "confirmed", child: Text("Confirmed")),
                DropdownMenuItem(value: "cancelled", child: Text("Cancelled")),
              ],
              onChanged: (value) {
                setState(() {
                  status = value ?? status;
                });
              },
            ),
            SizedBox(height: 20),
            Text(
              "Prix total calculé : ${totalPrice.toStringAsFixed(2)} €",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  "Modifier la commande",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
