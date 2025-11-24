import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:foodie_order/globals.dart' as globals;

class EditMealForm extends StatefulWidget {
  final Map<String, dynamic> meal;
  final VoidCallback onMealUpdated;

  const EditMealForm({
    Key? key,
    required this.meal,
    required this.onMealUpdated,
  }) : super(key: key);

  @override
  State<EditMealForm> createState() => _EditMealFormState();
}

class _EditMealFormState extends State<EditMealForm> {
  TextEditingController controllerName = TextEditingController();
  TextEditingController controllerDescription = TextEditingController();
  TextEditingController controllerPrice = TextEditingController();

  Uint8List? _newImageBytes;
  String? _newFileName;

  // 🌄 Image actuelle
  late String oldImagePath;

  Future<void> pickNewImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _newImageBytes = result.files.single.bytes!;
        _newFileName = result.files.single.name;
      });
    }
  }

  // --- ENVOI DES DONNÉES ---
  Future<void> editMealRequest() async {
    var url = Uri.parse("${globals.baseUrl}edit_meal.php");

    var request = http.MultipartRequest("POST", url);

    // Champs texte
    request.fields['id'] = widget.meal['id'].toString();
    request.fields['name'] = controllerName.text;
    request.fields['description'] = controllerDescription.text;
    request.fields['price'] = controllerPrice.text;

    // Si nouvelle image → envoyer
    if (_newImageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _newImageBytes!,
          filename: _newFileName ?? "meal.jpg",
        ),
      );
    } else {
      // Si pas de nouvelle image, envoyer l'ancien chemin
      request.fields['old_image'] = oldImagePath;
    }

    try {
      var response = await request.send();

      var body = await response.stream.bytesToString();
      var data = jsonDecode(body);

      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Repas modifié avec succès!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Échec modification: ${data['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    controllerName.text = widget.meal['name'] ?? '';
    controllerDescription.text = widget.meal['description'] ?? '';
    controllerPrice.text = widget.meal['price'].toString();

    oldImagePath = widget.meal['image'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: controllerName,
              decoration: const InputDecoration(labelText: "Nom"),
            ),
            TextFormField(
              controller: controllerDescription,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            TextFormField(
              controller: controllerPrice,
              decoration: const InputDecoration(labelText: "Prix"),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            // --- PREVIEW IMAGE ---
            _newImageBytes != null
                ? Image.memory(_newImageBytes!, height: 120)
                : (oldImagePath.isNotEmpty
                    ? Image.network(
                        "${globals.baseUrl}$oldImagePath",
                        height: 120,
                      )
                    : const Text("Aucune image")),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: pickNewImage,
              child: const Text("Changer l'image"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await editMealRequest();
                widget.onMealUpdated();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text("Modifier"),
            ),
          ],
        ),
      ),
    );
  }
}
