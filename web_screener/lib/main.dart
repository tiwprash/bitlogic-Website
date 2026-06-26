import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/strategy_tab.dart';
import 'providers/strategy_provider.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StrategyProvider()..loadStrategies()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const WebScreenerApp(),
    ),
  );
}

class WebScreenerApp extends StatelessWidget {
  const WebScreenerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Screener Web',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const Scaffold(
        body: StrategyTab(),
      ),
    );
  }
}
