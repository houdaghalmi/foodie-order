import 'package:flutter/material.dart';
import 'package:foodie_order/user/home_page.dart' as UserHome;
import 'package:foodie_order/admin/home_page.dart' as AdminHome;
import 'auth/login_form.dart';
import 'auth/register_form.dart';
import 'admin/meals/add_meals.dart';
import 'admin/meals/list_meals.dart';
import 'user/order/add_order.dart';
import 'user/order/list_orders.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion des commandes ',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,

      initialRoute: '/',
      routes: {
        '/': (context) => LandingHome(),
        '/register': (context) => RegisterForm(),
        '/login': (context) => LoginForm(),
        '/admin_home': (context) => AdminHome.HomePage(),
        '/user_home': (context) => UserHome.HomePage(),
        '/add_meals': (context) => AddMealForm(onMealAdded: () {}),
        '/list_meals': (context) => ListMeals(),

        '/add_order': (context) {
          final username =
              ModalRoute.of(context)!.settings.arguments as String?;
          return AddOrderForm(username: username, onOrderAdded: () {});
        },
        '/list_orders': (context) {
          final username =
              ModalRoute.of(context)!.settings.arguments as String?;
          return ListOrders(username: username);
        },
      },
    );
  }
}
