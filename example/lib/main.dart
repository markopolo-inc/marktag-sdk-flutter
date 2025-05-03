import 'package:flutter/material.dart';
import 'package:marktag/marktag.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Marktag.instance.init(tag: 'test-tag.website.com');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marktag Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Marktag Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Marktag.instance.logLogin(
                    email: 'test@test.com',
                    name: 'Test User',
                    phone: '+1234567890',
                  );
                },
                child: Text('Log Login'),
              ),
              ElevatedButton(
                onPressed: () {
                  Marktag.instance.logEvent(
                    MarkTagEvent(
                      event: 'TestEvent',
                      metadata: {'sdk': 'flutter'},
                    ),
                  );
                },
                child: Text('Log Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
