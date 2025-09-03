import 'package:TeaLink/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:TeaLink/constants/colors.dart';
 // <-- added

class FrontPage extends StatelessWidget {
  const FrontPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!; // <-- added

    return Container(
      decoration: const BoxDecoration(
        color: kWhite,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                loc.welcome, // <-- localized
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: kMainColor,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Image.asset(
              'assets/images/TeaLink.png',
              height: 400,
              width: 400,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
