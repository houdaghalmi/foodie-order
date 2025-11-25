import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String user = ModalRoute.of(context)!.settings.arguments as String;
    return Scaffold(
      appBar: AppBar(title: Text("Page d'accueil utilisateur")),
      body: Container(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text("Bienvenue USER $user"),
            Image(image: AssetImage("images/dashboard.png")),
          
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/add_order', arguments: user);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: Text("Ajouter une commande"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/list_orders', arguments: user);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: Text("Liste des commandes"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text("Se déconnecter"),
            ),
          ],
        ),
      ),
    );
  }
}
