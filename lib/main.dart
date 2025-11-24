import 'package:flutter/material.dart';
import 'package:foodie_order/home_page.dart';
import 'auth/login_form.dart';
import 'auth/register_form.dart';
import 'meals/add_meals.dart';
import 'meals/list_meals.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //get user => null;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion des articles',
      theme: ThemeData(primarySwatch: Colors.blue),

      initialRoute: '/',
      routes: {
        '/': (context) => LoginForm(),
        '/register': (context) => RegisterForm(),
        '/login': (context) => LoginForm(),
        '/home': (context) => HomePage(),
        '/add_meals': (context) => AddMealForm(onMealAdded: () {}),
        '/list_meals': (context) => ListMeals(),
        
       
      
       
      
       
      },
    );
  }
}
