import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:TeaLink/constants/colors.dart';
import 'package:TeaLink/data/onboarding_data.dart';
import 'package:TeaLink/pages/onboarding/front_page.dart';
import 'package:TeaLink/pages/onboarding/shared_onboarding_screen.dart';
import 'package:TeaLink/pages/user_registration_screen.dart';
import 'package:TeaLink/widgets/custom_button.dart';

// ignore: camel_case_types
class onboardingScreen extends StatefulWidget {
  const onboardingScreen({super.key});

  @override
  State<onboardingScreen> createState() => _onboardingScreenState();
}

// ignore: camel_case_types
class _onboardingScreenState extends State<onboardingScreen> {
  final PageController _controller = PageController();
  bool  showDetailsPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: 
          Stack(
            children: [
              PageView(
                controller: _controller,
                onPageChanged: (value) {
                  setState(() {
                    
                    showDetailsPage = value == 2;
                  });
                },
                children: [
                  FrontPage(),
                  SharedOnboardingScreen(title: OnboardingData.onBoardingDataList[0].title, description: OnboardingData.onBoardingDataList[0].description, imagepath: OnboardingData.onBoardingDataList[0].imagepath),
                  SharedOnboardingScreen(title: OnboardingData.onBoardingDataList[1].title, description: OnboardingData.onBoardingDataList[1].description, imagepath: OnboardingData.onBoardingDataList[1].imagepath),
                  

                ],
              ),
              Container(
                alignment: Alignment(0, 0.75),
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
                  child: !showDetailsPage
                      ? GestureDetector(
                          onTap: () {
                            _controller.animateToPage(
                              _controller.page!.toInt() + 1,
                              duration: Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: CustemButton(
                            buttonName: showDetailsPage ? "Get Started" : "Next",
                            // ignore: deprecated_member_use
                            buttonColor: kMainColor.withOpacity(0.9),
                          ),
                        )
                      : GestureDetector(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => UserRegistrationScreen()));
                        },
                        child: CustemButton(buttonName: showDetailsPage? "Get Started" : "Next",
                        // ignore: deprecated_member_use
                        buttonColor: kMainColor.withOpacity(0.9),),
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}