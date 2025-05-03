import 'package:flutter/material.dart';
import 'package:marktag/marktag.dart';

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Demo Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: TextFormField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Search',
              suffixIcon: IconButton(
                onPressed: () {
                  Marktag.instance.logSearch(searchController.text);
                  searchController.clear();
                },
                icon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
