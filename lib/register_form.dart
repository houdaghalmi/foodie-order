import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:foodie_order/globals.dart' as globals;

class RegisterForm extends StatefulWidget {
  const RegisterForm({Key? key}) : super(key: key);

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  TextEditingController controllerUsername = TextEditingController();
  TextEditingController controllerPassword = TextEditingController();
  TextEditingController controllerEmail = TextEditingController();

  Future register() async {
    var url = Uri.parse("${globals.baseUrl}register.php");

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "username": controllerUsername.text,
          "password": controllerPassword.text,
          "email": controllerEmail.text,
        }),
      );

      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        var data = json.decode(response.body);

        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Inscription réussie !")),
          );
          Navigator.pushNamed(context, '/login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Erreur d'inscription")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Réponse du serveur non au format JSON")),
        );
      }
    } catch (e) {
      print("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau ou serveur indisponible.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 100),
                Image.asset("images/register.png"),
                Text(
                  "Créer un compte",
                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                ),

                // Username
                TextFormField(
                  controller: controllerUsername,
                  decoration: InputDecoration(
                    hintText: "Nom d'utilisateur",
                    labelText: "Nom d'utilisateur",
                  ),
                ),

                // Email
                TextFormField(
                  controller: controllerEmail,
                  decoration: InputDecoration(
                    hintText: "Email",
                    labelText: "Email",
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                // Password
                TextFormField(
                  controller: controllerPassword,
                  decoration: InputDecoration(
                    hintText: "Mot de passe",
                    labelText: "Mot de passe",
                  ),
                  obscureText: true,
                ),

                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Text("S'inscrire"),
                ),

                SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/');
                  },
                  child: Text("Vous avez déjà un compte ? Se connecter"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
