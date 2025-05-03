import 'package:example/demo_page.dart';
import 'package:flutter/material.dart';
import 'package:marktag/marktag.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Marktag.instance.init(tag: 'test-tag.website.com', enableLogging: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marktag Example',
      navigatorObservers: [
        // Add this observer to automatically log page views
        MarktagNavigatorObserver(
          marktag: Marktag.instance,
        ),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
      routes: {
        // Route name must be set for automatic logging. If you use navigator 2.0, this is automatically done.
        '/demo': (context) => const DemoPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marktag Example'),
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
              child: const Text('Log Login'),
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
              child: const Text('Log Event'),
            ),
            ElevatedButton(
              onPressed: () {
                Marktag.instance.logEvent(
                  MarkTagEvent(
                    event: 'ViewItem',
                    pageUrl: '/',
                    items: [
                      MarkTagEventItem(
                        id: '123',
                        name: 'Test Item',
                        price: 100,
                        quantity: 1,
                        category: 'Test Category',
                        variant: 'Test Variant',
                        coupon: 'TEST123',
                        discount: 10,
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Log View Item'),
            ),
            ElevatedButton(
              onPressed: () {
                Marktag.instance.logPageView('test-page');
              },
              child: const Text('Log Page View (Manual logging)'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/demo');
              },
              child: const Text('Go to Demo Page (Automatic logging)'),
            ),
          ],
        ),
      ),
    );
  }
}
