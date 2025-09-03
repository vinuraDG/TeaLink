import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/language_service.dart';

class LanguageSwitcherWidget extends StatelessWidget {
  final bool showLabel;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  
  const LanguageSwitcherWidget({
    Key? key,
    this.showLabel = true,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return PopupMenuButton<String>(
      onSelected: (String languageCode) async {
        await languageProvider.changeLanguage(languageCode);
      },
      itemBuilder: (BuildContext context) {
        return LanguageService.getSupportedLocales().map((locale) {
          final isSelected = languageProvider.currentLocale.languageCode == locale.languageCode;
          return PopupMenuItem<String>(
            value: locale.languageCode,
            child: Row(
              children: [
                Text(
                  locale.languageCode == 'en' ? '🇬🇧' : '🇱🇰',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  LanguageService.getLanguageName(
                    locale.languageCode,
                    languageProvider.currentLocale.languageCode,
                  ),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  const Icon(Icons.check, color: Colors.green, size: 20),
                ],
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: backgroundColor != null 
              ? Border.all(color: (textColor ?? Colors.white).withOpacity(0.3))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              color: iconColor ?? Colors.white,
              size: 20,
            ),
            if (showLabel) ...[
              const SizedBox(width: 8),
              Text(
                languageProvider.isSinhala ? 'සිං' : 'EN',
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Settings page language switcher
class LanguageSettingsTile extends StatelessWidget {
  const LanguageSettingsTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(
        languageProvider.isSinhala ? 'භාෂාව' : 'Language',
      ),
      subtitle: Text(
        LanguageService.getLanguageName(
          languageProvider.currentLocale.languageCode,
          languageProvider.currentLocale.languageCode,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pushNamed(context, '/language-settings');
      },
    );
  }
}