import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/constants/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isUser ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUser ? 20 : 0),
              bottomRight: Radius.circular(isUser ? 0 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUser ? Icons.person : Icons.account_balance,
                    size: 14,
                    color: isUser ? AppColors.secondary : AppColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isUser ? 'You' : 'CVI Assistant',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isUser ? AppColors.white.withValues(alpha: 0.7) : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              isUser
                  ? Text(
                      text,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                      ),
                    )
                  : MarkdownBody(
                      data: text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          color: AppColors.textBody,
                          fontSize: 15,
                          height: 1.4,
                        ),
                        strong: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        em: const TextStyle(
                          color: AppColors.textBody,
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                        ),
                        h1: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        h2: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        listBullet: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                        ),
                        code: const TextStyle(
                          fontSize: 13,
                          backgroundColor: AppColors.bgDeep,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
