import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';

class TText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final double? textScaleFactor;

  const TText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    LanguageProvider? lang;
    try {
      lang = context.watch<LanguageProvider>();
    } catch (_) {
      lang = null;
    }
    final translated = lang?.translateSync(text) ?? text;

    return Text(
      translated,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      // ignore: deprecated_member_use
      textScaleFactor: textScaleFactor,
    );
  }
}
