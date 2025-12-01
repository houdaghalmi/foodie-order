import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:foodie_order/globals.dart' as globals;

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  // Controllers
  TextEditingController controllerEmail = TextEditingController();
  TextEditingController controllerPassword = TextEditingController();

  // Fonction login
  Future login() async {
    var url = Uri.parse("${globals.baseUrl}login.php");

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "email": controllerEmail.text,
          "password": controllerPassword.text,
        }),
      );

      if (response.headers['content-type']?.contains('application/json') ?? false) {
        var data = json.decode(response.body);

        if (data['success'] == true) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Connexion réussie !")));

          String role = data['role'] ?? 'user';

          if (role == 'admin') {
            Navigator.pushNamed(context, '/admin_home', arguments: controllerEmail.text);
          } else {
            Navigator.pushNamed(context, '/user_home', arguments: controllerEmail.text);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Réponse serveur non valide")),
        );
      }
    } catch (e) {
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
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(height: 100),
                Image.asset("assets/images/auth.png"),

                Text("Connexion",
                    style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),

                // email
                TextFormField(
                  controller: controllerEmail,
                  decoration: InputDecoration(
                    hintText: "Email",
                    labelText: "Email",
                  ),
                ),

                SizedBox(height: 10),

                // password
                TextFormField(
                  controller: controllerPassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Mot de passe",
                    labelText: "Mot de passe",
                  ),
                ),

                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: Text("Se connecter"),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text(
                    "Pas encore de compte ? S'inscrire",
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
