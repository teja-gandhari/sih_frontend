import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/welcome/welcome_screen.dart';

import '../screens/onboarding/language_screen.dart';
import '../screens/onboarding/location_screen.dart';
import '../screens/onboarding/margin_capital_screen.dart';
import '../screens/onboarding/business_category_screen.dart';
import '../screens/onboarding/review_screen.dart';
import '../screens/analysis/financial_screen.dart';
import '../screens/scheme/scheme_result_screen.dart';
import '../screens/market/market_analysis_screen.dart';
import '../screens/feasibility/feasibility_score_screen.dart';
import '../screens/advisor/ai_advisor_screen.dart';
import '../screens/dashboard/final_dashboard_screen.dart';

class AppRouter {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  static const String language = '/language';
  static const String location = '/location';
  static const String marginCapital = '/marginCapital';
  static const String businessCategory = '/businessCategory';
  static const String review = '/review';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return _protectedRoute(const HomeScreen());
      case language:
        return _protectedRoute(const LanguageScreen());
      case location:
        return _protectedRoute(const LocationScreen());
      case marginCapital:
        return _protectedRoute(const MarginCapitalScreen());
      case businessCategory:
        return _protectedRoute(const BusinessCategoryScreen());
      case review:
        return _protectedRoute(const ReviewScreen());
      case '/financial':
        return _protectedRoute(const FinancialScreen());
      case '/scheme':
        return _protectedRoute(const SchemeResultScreen());
      case '/market':
        return _protectedRoute(const MarketAnalysisScreen());
      case '/feasibility':
        return _protectedRoute(const FeasibilityScoreScreen());
      case '/advisor':
        return _protectedRoute(const AiAdvisorScreen());
      case '/dashboard':
        return _protectedRoute(const FinalDashboardScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
    }
  }

  static MaterialPageRoute _protectedRoute(Widget child) {
    return MaterialPageRoute(
      builder: (context) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.status == AuthStatus.authenticated) {
          return child;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(login);
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
