import 'package:TeaLink/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:TeaLink/constants/colors.dart';
import 'package:TeaLink/data/onboarding_data.dart';
import 'package:TeaLink/pages/onboarding/front_page.dart';
import 'package:TeaLink/pages/onboarding/shared_onboarding_screen.dart';
import 'package:TeaLink/pages/user_registration_screen.dart';
import 'package:TeaLink/widgets/custom_button.dart';
import 'package:TeaLink/providers/language_provider.dart';
import 'package:TeaLink/widgets/language_switcher_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool showDetailsPage = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        // Get localized strings - this will automatically update when language changes
        final loc = AppLocalizations.of(context)!;
        
        // Get localized onboarding data
        final onboardingData = OnboardingData.getData(context);

        return Scaffold(
          // Add language switcher in app bar
          appBar: AppBar(
            backgroundColor: kWhite,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: LanguageSwitcherWidget(
                  iconColor: kMainColor,
                  textColor: kMainColor,
                  backgroundColor: kMainColor.withOpacity(0.1),
                ),
              ),
            ],
          
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    PageView(
                      controller: _controller,
                      onPageChanged: (value) {
                        setState(() {
                          showDetailsPage = value == 2;
                        });
                      },
                      children: [
                        const FrontPage(),
                        SharedOnboardingScreen(
                          title: onboardingData[0].title,
                          description: onboardingData[0].description,
                          imagepath: onboardingData[0].imagepath,
                        ),
                        SharedOnboardingScreen(
                          title: onboardingData[1].title,
                          description: onboardingData[1].description,
                          imagepath: onboardingData[1].imagepath,
                        ),
                      ],
                    ),
                    
                    Container(
                      alignment: const Alignment(0, 0.75),
                      child: SmoothPageIndicator(
                        controller: _controller,
                        count: 3,
                        effect: WormEffect(
                          dotHeight: 10,
                          dotWidth: 10,
                          activeDotColor: kMainColor,
                          dotColor: kLightGrey,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: !showDetailsPage
                              ? GestureDetector(
                                  key: const ValueKey('next_button'),
                                  onTap: () {
                                    _controller.animateToPage(
                                      _controller.page!.toInt() + 1,
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: CustemButton(
                                    buttonName: loc.next,
                                    buttonColor: kMainColor.withOpacity(0.9),
                                  ),
                                )
                              : GestureDetector(
                                  key: const ValueKey('get_started_button'),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const UserRegistrationScreen(),
                                      ),
                                    );
                                  },
                                  child: CustemButton(
                                    buttonName: loc.getStarted,
                                    buttonColor: kMainColor.withOpacity(0.9),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}