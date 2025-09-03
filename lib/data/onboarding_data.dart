import 'package:TeaLink/l10n/app_localizations.dart';

import 'package:TeaLink/models/onboarding_model.dart';
import 'package:flutter/material.dart';

class OnboardingData {
  static List<OnboardingModel> getData(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      OnboardingModel(
        title: loc.onboarding1Title,
        description: loc.onboarding1Description,
        imagepath: "assets/images/Tea.jpg",
      ),
      OnboardingModel(
        title: loc.onboarding2Title,
        description: loc.onboarding2Description,
        imagepath: "assets/images/collector.jpg",
      ),
    ];
  }
}
