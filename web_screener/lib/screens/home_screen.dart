import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold();

  static final GlobalKey drawerButtonKey = GlobalKey();
  static final GlobalKey newStrategyButtonKey = GlobalKey();
  static final GlobalKey libraryButtonKey = GlobalKey();
  static final GlobalKey saveButtonKey = GlobalKey();
  static final GlobalKey strategyNameKey = GlobalKey();
  static final GlobalKey marketConfigKey = GlobalKey();
  static final GlobalKey timeframeConfigKey = GlobalKey();
  static final GlobalKey rulesListKey = GlobalKey();
  static final GlobalKey addRuleButtonsKey = GlobalKey();
  static final GlobalKey riskConfigKey = GlobalKey();
  static final GlobalKey scanButtonKey = GlobalKey();
}
