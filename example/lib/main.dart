import 'package:flutter/material.dart';

import 'profile_screen.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'ExtendedNestedScrollView',
      debugShowCheckedModeBanner: false,
      home: ProfileScreen(),
    );
  }
}