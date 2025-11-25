import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:foodie_order/globals.dart' as globals;

class EditOrderForm extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onOrderUpdated;

  EditOrderForm({required this.order, required this.onOrderUpdated});

  @override
  _EditOrderFormState createState() => _EditOrderFormState();
}

class _EditOrderFormState extends State<EditOrderForm> {
  TextEditingController qtyCtrl = TextEditingController();
  TextEditingController priceCtrl = TextEditingController();
  String status = "pending";

  @override
  void initState() {
    super.initState();
    qtyCtrl.text = widget.order["quantity"].toString();
    priceCtrl.text = widget.order["total_price"].toString();
    status = widget.order["status"] ?? "pending";
  }

  Future<void> updateOrder() async {
    var url = Uri.parse("${globals.baseUrl}edit_order.php");

    var request = http.MultipartRequest("POST", url);

    request.fields["id"] = widget.order["id"].toString();
    request.fields["quantity"] = qtyCtrl.text;
    request.fields["total_price"] = priceCtrl.text;
    request.fields["status"] = status;

    var response = await request.send();
    var jsonResp = await response.stream.bytesToString();
    var data = jsonDecode(jsonResp);

    if (data["success"]) {
      widget.onOrderUpdated();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Commande modifiée !")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(controller: qtyCtrl, decoration: InputDecoration(labelText: "Quantité")),
          TextField(controller: priceCtrl, decoration: InputDecoration(labelText: "Prix total")),

          DropdownButton<String>(
            value: status,
            items: ["pending", "confirmed", "cancelled"]
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => setState(() => status = val!),
          ),

          SizedBox(height: 20),

          ElevatedButton(
            onPressed: updateOrder,
            child: Text("Modifier"),
          ),
        ],
      ),
    );
  }
}
