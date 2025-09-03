import 'package:TeaLink/data/onboarding_data.dart';
import 'package:TeaLink/pages/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:TeaLink/main.dart';
import 'package:TeaLink/providers/language_provider.dart';
import 'package:TeaLink/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('TeaLink App Tests', () {
    
    testWidgets('App launches and shows onboarding screen', (WidgetTester tester) async {
      // Create a mock language provider
      final languageProvider = LanguageProvider();
      
      // Build our app and trigger a frame
      await tester.pumpWidget(
        ChangeNotifierProvider<LanguageProvider>.value(
          value: languageProvider,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('si'),
            ],
            home: const OnboardingScreen(),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify that the welcome text is displayed (should be in English by default)
      expect(find.text('Welcome'), findsOneWidget);
      
      // Verify that the Next button is displayed
      expect(find.text('Next'), findsOneWidget);
      
      // Verify that language switcher icon is present
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('Navigation through onboarding screens works', (WidgetTester tester) async {
      final languageProvider = LanguageProvider();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<LanguageProvider>.value(
          value: languageProvider,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('si'),
            ],
            home: const OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify we're on the first page (Welcome page)
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Tap the Next button to go to first onboarding page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify we're on the first onboarding screen
      expect(find.textContaining('Track weekly'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Tap Next again to go to second onboarding page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify we're on the second onboarding screen
      expect(find.textContaining('View Collector'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Language switcher is accessible', (WidgetTester tester) async {
      final languageProvider = LanguageProvider();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<LanguageProvider>.value(
          value: languageProvider,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('si'),
            ],
            home: const OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the language switcher
      final languageSwitcher = find.byIcon(Icons.language);
      expect(languageSwitcher, findsOneWidget);
      
      await tester.tap(languageSwitcher);
      await tester.pumpAndSettle();

      // Verify language options are shown (this depends on your LanguageSwitcherWidget implementation)
      // You might need to adjust this based on how your popup menu works
      expect(find.text('English'), findsOneWidget);
      expect(find.text('සිංහල'), findsOneWidget);
    });

    testWidgets('Smooth page indicator is present', (WidgetTester tester) async {
      final languageProvider = LanguageProvider();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<LanguageProvider>.value(
          value: languageProvider,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('si'),
            ],
            home: const OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if SmoothPageIndicator is present (it creates multiple dots)
      // The exact finder depends on your SmoothPageIndicator implementation
      expect(find.byType(PageView), findsOneWidget);
    });
  });

  group('Language Provider Tests', () {
    test('Language provider initializes with English by default', () {
      final languageProvider = LanguageProvider();
      expect(languageProvider.currentLocale.languageCode, equals('en'));
      expect(languageProvider.isEnglish, isTrue);
      expect(languageProvider.isSinhala, isFalse);
    });
  });

  group('Onboarding Data Tests', () {
    testWidgets('Onboarding data provides correct localized content', (WidgetTester tester) async {
      // Test English content
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('si'),
          ],
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final onboardingData = OnboardingData.getData(context);
              return Scaffold(
                body: Column(
                  children: [
                    Text(onboardingData[0].title),
                    Text(onboardingData[1].title),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify English onboarding titles are present
      expect(find.textContaining('Track weekly'), findsOneWidget);
      expect(find.textContaining('View Collector'), findsOneWidget);
    });
  });
}