import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  static const route = '/about';
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'About',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Colors.white),
        ),
      ),
      body: ListView(
        children: const [
          ListTile(
            title: Text('Made with ❤ by : Goodness Emmanuel'),
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: SelectableText('goodnessemma05@gmail.com'),
          ),
        ],
      ),
    );
  }
}
