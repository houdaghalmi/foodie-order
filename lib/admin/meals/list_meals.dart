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
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchMeals();
  }

  Future<void> _fetchMeals() async {
    setState(() {
      _isLoading = true;
    });

    var url = Uri.parse("${globals.baseUrl}list_meals.php");

    try {
      var response = await http.get(url);

      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        var data = json.decode(response.body);
        setState(() {
          _meals = data['meals'] ?? [];
          _isLoading = false;
          _isRefreshing = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Réponse du serveur non au format JSON"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      print('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur réseau ou serveur indisponible."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToAddMeal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text("Ajouter un repas"),
            backgroundColor: Colors.white,
            elevation: 1,
          ),
          body: AddMealForm(onMealAdded: _fetchMeals),
        ),
      ),
    );
  }

  void _navigateToEditMeal(Map<String, dynamic> meal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text("Modifier le repas"),
            backgroundColor: Colors.white,
            elevation: 1,
          ),
          body: EditMealForm(
            meal: meal,
            onMealUpdated: () {
              _fetchMeals();
              Navigator.pop(context); // Retour à la liste après modification
            },
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMeal(int mealId, String mealName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Confirmer la suppression',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Êtes-vous sûr de vouloir supprimer le repas :',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                '"$mealName"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Annuler',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        _isLoading = true;
      });

      var url = Uri.parse("${globals.baseUrl}delete_meal.php");
      try {
        var response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'id': mealId.toString()}),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          var data = json.decode(response.body);
          if (data['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Repas supprimé avec succès"),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _fetchMeals();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? "Erreur lors de la suppression"),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Réponse du serveur non au format JSON"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print('Exception: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur réseau ou serveur indisponible."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    var imageUrl = meal['image'];
    var fullImageUrl = imageUrl != null && imageUrl.isNotEmpty
        ? "${globals.baseUrl}$imageUrl"
        : null;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToEditMeal(meal),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du repas
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                  image: fullImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(fullImageUrl),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            // Error handling - the icon is shown by the child widget below
                          },
                        )
                      : null,
                ),
                child: fullImageUrl == null
                    ? Center(
                        child: Icon(
                          Icons.fastfood,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 16),

              // Informations du repas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            meal['name'] ?? 'Sans nom',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${meal['price'] ?? '0'} DT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (meal['description'] != null && meal['description'].isNotEmpty)
                      Text(
                        meal['description'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> meal) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _navigateToEditMeal(meal),
              icon: Icon(Icons.edit, size: 18),
              label: Text('Modifier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _deleteMeal(meal['id'], meal['name'] ?? 'ce repas'),
              icon: Icon(Icons.delete, size: 18),
              label: Text('Supprimer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff9f9f9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black12,
        title: Text(
          "Liste des repas",
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.green),
            onPressed: _fetchMeals,
            tooltip: "Actualiser",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddMeal,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: Icon(Icons.add),
        label: Text("Ajouter"),
      ),
      body: _isLoading && _meals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 20),
                  Text(
                    "Chargement des repas...",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : _meals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Aucun repas disponible",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Commencez par ajouter votre premier repas",
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _navigateToAddMeal,
                        icon: Icon(Icons.add),
                        label: Text("Ajouter un repas"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _isRefreshing = true;
                    });
                    await _fetchMeals();
                  },
                  color: Colors.green,
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: 16, bottom: 80),
                    itemCount: _meals.length,
                    itemBuilder: (context, index) {
                      var meal = _meals[index];
                      return Column(
                        children: [
                          _buildMealCard(meal),
                          _buildActionButtons(meal),
                          if (index < _meals.length - 1)
                            Divider(
                              height: 20,
                              thickness: 1,
                              indent: 16,
                              endIndent: 16,
                              color: Colors.grey[200],
                            ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }
}