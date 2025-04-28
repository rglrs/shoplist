import 'package:flutter/material.dart';
import 'package:todo_app/pages/sign_in.dart';
import 'package:todo_app/pages/sign_up.dart';
import 'package:todo_app/pages/shoplist_page.dart';
import 'package:todo_app/pages/profile.dart';
import 'package:todo_app/pages/edit_profile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo App',
      initialRoute: '/signIn',
      routes: {
        '/signIn': (context) => const SignIn(),
        '/signUp': (context) => const SignUp(),
        '/shopList': (context) => const ShopListPage(),
        '/profile': (context) => const Profile(),
        '/editProfile': (context) => const EditProfile(),
      },
    );
  }
}
