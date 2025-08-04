import 'package:flutter/material.dart';
import 'package:tealink/constants/colors.dart';
import 'package:tealink/constants/constant.dart';

class SharedOnboardingScreen extends StatelessWidget {

  final String title;
  final String description;
  final String imagepath;

  const SharedOnboardingScreen({super.key, required this.title, required this.description, required this.imagepath,});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(kdefaultPadding),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(kdefaultBoarderRadius),
                  child: Image.asset(
                    imagepath,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36,
                    color: kBlack,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    // ignore: deprecated_member_use
                    color: kBlack.withOpacity(0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}