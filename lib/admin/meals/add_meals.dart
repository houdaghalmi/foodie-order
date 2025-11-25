import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:foodie_order/globals.dart' as globals;

class AddMealForm extends StatefulWidget {
  final VoidCallback onMealAdded;

  const AddMealForm({super.key, required this.onMealAdded});

  @override
  State<AddMealForm> createState() => _AddMealFormState();
}

class _AddMealFormState extends State<AddMealForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  Uint8List? _imageBytes;
  String? _fileName;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        _imageBytes = result.files.single.bytes!;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _addMeal() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Veuillez choisir une image")));
      return;
    }

    double? price =
        double.tryParse(_priceCtrl.text.replaceAll(",", "."));
    if (price == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Prix invalide")));
      return;
    }

    final url = Uri.parse("${globals.baseUrl}add_meals.php");

    try {
      final request = http.MultipartRequest("POST", url);

      request.fields["name"] = _nameCtrl.text;
      request.fields["description"] = _descCtrl.text;
      request.fields["price"] = price.toString();

      request.files.add(
        http.MultipartFile.fromBytes(
          "image",
          _imageBytes!,
          filename: _fileName ?? "meal.jpg",
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);

      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Repas ajouté avec succès !")),
        );

        widget.onMealAdded();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ${data['message']}")),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur réseau.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Add Scaffold here
      appBar: AppBar(
        title: const Text("Ajouter un repas"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Nom du repas"),
            ),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: "Prix"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            _imageBytes != null
                ? Image.memory(_imageBytes!, height: 120)
                : const Text("Aucune image sélectionnée"),

            ElevatedButton(
              onPressed: _pickImage,
              child: const Text("Choisir une image"),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addMeal,
              child: const Text("Ajouter le repas"),
            ),
          ],
        ),
      ),
    );
  }
}