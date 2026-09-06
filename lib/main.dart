import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/app_state_provider.dart';
import 'services/auth_service.dart';
import 'services/onboarding_service.dart';
import 'services/financial_service.dart';
import 'providers/financial_provider.dart';
import 'services/scheme_service.dart';
import 'providers/scheme_provider.dart';
import 'services/market_service.dart';
import 'providers/market_provider.dart';
import 'services/feasibility_service.dart';
import 'providers/feasibility_provider.dart';
import 'services/advisory_service.dart';
import 'providers/advisory_provider.dart';
import 'services/report_service.dart';
import 'providers/report_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = SecureStorageService();
  final apiClient = ApiClient(storageService);
  final authService = AuthService(apiClient);
  final onboardingService = OnboardingService(apiClient);
  final financialService = FinancialService(apiClient);
  final schemeService = SchemeService(apiClient);
  final marketService = MarketService(apiClient);
  final feasibilityService = FeasibilityService(apiClient);
  final advisoryService = AdvisoryService(apiClient);
  final reportService = ReportService(apiClient);

  final authProvider = AuthProvider(authService, storageService);
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(
          create: (_) => FinancialProvider(financialService),
        ),
        ChangeNotifierProvider(create: (_) => SchemeProvider(schemeService)),
        ChangeNotifierProvider(create: (_) => MarketProvider(marketService)),
        ChangeNotifierProvider(
          create: (_) => FeasibilityProvider(feasibilityService),
        ),
        ChangeNotifierProvider(
          create: (_) => AdvisoryProvider(advisoryService),
        ),
        ChangeNotifierProvider(create: (_) => ReportProvider(reportService)),
        Provider.value(value: onboardingService),
        Provider.value(value: marketService),
      ],
      child: const RuralBizApp(),
    ),
  );
}
