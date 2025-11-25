import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:foodie_order/globals.dart' as globals;
import 'dart:convert';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  //Pour récupérer le texte saisi par l'utilisateur
  TextEditingController controllerusername = TextEditingController();
  TextEditingController controllerpassword = TextEditingController();

  //login est un fonction asynchrone qui retournera un objet de type Future
  Future login() async {
    //L'URL du serveur 192.168.1.11 pointe vers le script PHP (login.php)
    var url = Uri.parse("${globals.baseUrl}login.php");
    try {
      /*La requête POST utilse le package http pour envoyer 
    les données d'authentification (username et password) sous forme de JSON*/
      var response = await http.post(
        url,
        //vérifier si le serveur a renvoyé une réponse JSON en vérifiant l'en-tête content-type.
        headers: {'Content-Type': 'application/json'},
        //username et password sont envoyés sous format json
        body: json.encode({
          "username": controllerusername.text,
          "password": controllerpassword.text,
        }),
      );
      // Assurez-vous que la réponse est du type JSON
      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        /*Si data['success'] est true, la connexion est réussie, et une SnackBar s'affiche pour informer l'utilisateur.
   Ensuite, l'utilisateur est redirigé vers la page HomePage*/
        var data = json.decode(response.body);

        if (data['success'] == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Connexion réussie!")));

          // Check if user is admin or regular user
          String role = data['role'] ?? 'user';
          print("User role: $role");

          if (role == 'admin') {
            Navigator.pushNamed(
              context,
              '/admin_home',
              arguments: controllerusername.text,
            );
          } else {
            Navigator.pushNamed(
              context,
              '/user_home',
              arguments: controllerusername.text,
            );
          }
        }
        //Sinon, un message d'erreur est affiché (soit data['message'], soit un message par défaut).
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Erreur de connexion")),
          );
        }
      }
      //Si la réponse n'est pas en JSON, une SnackBar indique que le format de la réponse est incorrect.
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Réponse du serveur non au format JSON")),
        );
      }
    }
    //si le serveur est indisponible, un message d'erreur est affiché dans la console, et une SnackBar informe l'utilisateur de l'erreur réseau.
    catch (e) {
      print('Exception: $e');
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
                Image.asset("images/login.png"),
                Text(
                  "Connexion",
                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: controllerusername,
                  decoration: InputDecoration(
                    hintText: "Nom d'utilisateur", // Placeholder
                    labelText: "Nom d'utilisateur", // Label
                  ),
                ),
                TextFormField(
                  controller: controllerpassword,
                  decoration: InputDecoration(
                    hintText: "Mot de passe", // Placeholder
                    labelText: "Mot de passe", // Label
                  ),
                  obscureText: true,
                ),
                Padding(padding: EdgeInsets.only(bottom: 20.0)),
                ElevatedButton(
                  onPressed: login,
                  child: Text("Se connecter"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                ),
                Padding(padding: EdgeInsets.only(bottom: 20.0)),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text(
                    "Pas encore de compte? S'inscrire",
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
