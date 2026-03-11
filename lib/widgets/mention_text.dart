import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MentionText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Function(String username)? onMentionTap;

  const MentionText({
    required this.text,
    this.style,
    this.onMentionTap,
  });

  @override
  Widget build(BuildContext context) {
    final brand = AppTheme.brandOf(context);
    final defaultStyle = style ?? DefaultTextStyle.of(context).style;

    // Parse @mentions
    final regex = RegExp(r'@(\w+)');
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Text before mention
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start), style: defaultStyle));
      }
      // The mention
      final username = match.group(1)!;
      spans.add(TextSpan(
        text: '@$username',
        style: defaultStyle.copyWith(color: brand, fontWeight: FontWeight.bold),
        recognizer: onMentionTap != null
            ? (TapGestureRecognizer()..onTap = () => onMentionTap!(username))
            : null,
      ));
      lastEnd = match.end;
    }

    // Remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: defaultStyle));
    }

    if (spans.isEmpty) {
      return Text(text, style: defaultStyle);
    }

    return RichText(text: TextSpan(children: spans));
  }
}
