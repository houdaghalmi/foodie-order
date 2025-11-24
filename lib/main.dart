import 'package:flutter/material.dart';
import 'package:foodie_order/home_page.dart';
import 'login_form.dart';
import 'register_form.dart';

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
        '/home': (context) => HomePage(),
       
      },
    );
  }
}
