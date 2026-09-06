import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sih/app/router.dart';
import 'package:sih/app/theme.dart';
import 'package:sih/core/localization/app_localizations.dart';
import 'package:sih/providers/app_state_provider.dart';
import 'package:sih/providers/auth_provider.dart';

class RuralBizApp extends StatelessWidget {
  const RuralBizApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final authProvider = context.watch<AuthProvider>();

    String initialRoute = AppRouter.welcome;
    if (authProvider.status == AuthStatus.authenticated) {
      initialRoute = AppRouter.home;
    }

    // Wrap with an overlay if loading is required, rather than swapping out MaterialApp
    Widget materialApp = MaterialApp(
      title: 'RuralBiz AI',
      theme: AppTheme.lightTheme,
      locale: Locale(appState.selectedLanguage),
      supportedLocales: const [
        Locale('en'),
        Locale('te'),
        Locale('hi'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
    );

    if (authProvider.status == AuthStatus.initial) {
       return MaterialApp(
         home: const Scaffold(body: Center(child: CircularProgressIndicator())),
       );
    }
    
    return materialApp;
  }
}
