import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:foodie_order/globals.dart' as globals;
import 'add_meals.dart'; 
import 'edit_meal_form.dart'; 

class ListMeals extends StatefulWidget {
  @override
  _ListMealsState createState() => _ListMealsState();
}

class _ListMealsState extends State<ListMeals> {
  List<dynamic> _meals = [];

  @override
  void initState() {
    super.initState();
    _fetchMeals();
  }

  Future<void> _fetchMeals() async {
    var url = Uri.parse("${globals.baseUrl}list_meals.php");

    try {
      var response = await http.get(url);

      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        var data = json.decode(response.body);
        setState(() {
          _meals = data['meals'] ?? [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Réponse du serveur non au format JSON")),
        );
      }
    } catch (e) {
      print('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau ou serveur indisponible.")),
      );
    }
  }

  void _showAddMealDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ajouter un Repas'),
          content: AddMealForm(onMealAdded: _fetchMeals),
        );
      },
    );
  }

  void _navigateToMealDetail(Map<String, dynamic> meal) {
    Navigator.pushNamed(
      context,
      '/mealDetail',
      arguments: meal,
    );
  }

  Future<void> _deleteMeal(int mealId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la Suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer ce repas ?'),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Supprimer'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      var url = Uri.parse("${globals.baseUrl}delete_meal.php");
      try {
        var response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'id': mealId.toString()}),
        );

        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          var data = json.decode(response.body);
          if (data['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Repas supprimé avec succès")),
            );
            _fetchMeals();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text("Erreur lors de la suppression du repas")),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Réponse du serveur non au format JSON")),
          );
        }
      } catch (e) {
        print('Exception: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur réseau ou serveur indisponible.")),
        );
      }
    }
  }

  void _editMeal(int mealId) {
    var mealToEdit = _meals.firstWhere((meal) => meal['id'] == mealId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier le Repas'),
          content: EditMealForm(
            meal: mealToEdit,
            onMealUpdated: () {
              _fetchMeals();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Liste des repas"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddMealDialog,
          ),
        ],
      ),
      body: _meals.isEmpty
          ? Center(
              child: Text(
                "Aucun repas disponible",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _meals.length,
              itemBuilder: (context, index) {
                var meal = _meals[index];
                var imageUrl = meal['image'];

                // Construire l'URL complète pour l'image
                var fullImageUrl = Uri.parse("${globals.baseUrl}$imageUrl");

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16.0),
                    leading: imageUrl != null && imageUrl.isNotEmpty
                        ? Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              image: DecorationImage(
                                image: NetworkImage(fullImageUrl.toString()),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Icon(Icons.fastfood, color: Colors.grey[600]),
                          ),
                    title: Text(
                      meal['name'] ?? 'Sans nom',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          meal['description'] ?? 'Pas de description',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${meal['price'] ?? '0'} €',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editMeal(meal['id']),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteMeal(meal['id']),
                        ),
                      ],
                    ),
                    onTap: () => _navigateToMealDetail(meal),
                  ),
                );
              },
            ),
    );
  }
}