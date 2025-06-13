import 'package:flutter/material.dart';
import 'package:tealink/constants/colors.dart';

class SharedOnboardingScreen extends StatelessWidget {

  final String title;
  final String description;
  final String imagepath;

  const SharedOnboardingScreen({super.key, required this.title, required this.description, required this.imagepath,});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          imagepath,
          width: 200,
          fit: BoxFit.cover,

        ),
        const SizedBox(
          height: 20,
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
          ),
          ),
          const SizedBox(
          height: 20,
        ),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: kGrey,
            fontWeight: FontWeight.w500,
          ),),
          const SizedBox(
          height: 20,
        ),
      ],
    );
  }
}