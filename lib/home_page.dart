import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String user = ModalRoute.of(context)!.settings.arguments as String;
    return Scaffold(
      appBar: AppBar(title: Text("Page d'accueil")),
      body: Container(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text("Bienvenue $user"),
            Image(image: AssetImage("images/dashboard.png")),
            SizedBox(height: 100),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/add_meals');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text("Ajouter un repas"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/list_meals');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text("Liste des repas"),
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
