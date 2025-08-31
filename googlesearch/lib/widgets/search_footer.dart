// ignore_for_file: unused_local_variable, use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googlesearch/Color/colors.dart';
import 'package:googlesearch/FeedBack/feedback_screen.dart';


class SearchFooter extends StatelessWidget {
  const SearchFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          color: theme.cardColor,
          padding: EdgeInsets.symmetric(
            horizontal: size.width <= 768 ? 10 : 150,
            vertical: 15,
          ),
          child: Row(
            children: [
              Text(
                'Bangladesh',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 20,
                width: 0.5,
                color: theme.dividerColor,
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.circle,
                color: theme.disabledColor,
                size: 12,
              ),
              const SizedBox(width: 10),
              Text(
                "Khulna KUET ",
                style: TextStyle(
                  fontSize: 14,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),

        Divider(
          thickness: 0,
          height: 0,
          color: theme.dividerColor,
        ),

        Container(
          color: theme.cardColor,
          padding: EdgeInsets.symmetric(
            horizontal: size.width <= 768 ? 20 : 50,
            vertical: 10,
          ),
          child: Row(
            children: [
            //  _footerLink(context, 'Help', theme),
              _footerLink(context, 'Send feedback', theme, isFeedback: true),
             // _footerLink(context, 'Privacy', theme),
              //_footerLink(context, 'Terms', theme),
            ],
          ),
        ),
      ],
    );
  }
Widget _footerLink(BuildContext context, String text, ThemeData theme, {bool isFeedback = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Material(
      color: isFeedback ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: isFeedback
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        splashColor: theme.primaryColor.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isFeedback ? theme.primaryColor : Colors.grey.withOpacity(0.4),
              width: 1.2,
            ),
            color: isFeedback ? theme.primaryColor.withOpacity(0.05) : null,
          ),
          child: Text(
            text,
            style: GoogleFonts.playfairDisplay(
              color: isFeedback
                  ? theme.primaryColor
                  : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              fontSize: 18,
              fontWeight: isFeedback ? FontWeight.bold : FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    ),
  );
}

}
