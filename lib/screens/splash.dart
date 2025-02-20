import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Text(
              'Smart Home',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ));
  }
}
