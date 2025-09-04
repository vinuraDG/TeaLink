import 'dart:ui';

String getFontFamily(Locale locale) {
  switch (locale.languageCode) {
    case 'si':
      return 'NotoSansSinhala';
    case 'en':
    default:
      return 'Roboto';
  }
}
