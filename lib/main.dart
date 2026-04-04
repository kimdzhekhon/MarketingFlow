import 'package:flutter/material.dart';
import 'app_state.dart';
import 'theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MarketingFlowApp());
}

class MarketingFlowApp extends StatefulWidget {
  const MarketingFlowApp({super.key});

  @override
  State<MarketingFlowApp> createState() => MarketingFlowAppState();
}

class MarketingFlowAppState extends State<MarketingFlowApp> {
  final appState = AppState();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => MaterialApp(
        title: 'MarketingFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: HomeScreen(appState: appState),
      ),
    );
  }
}
