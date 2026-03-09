import 'package:flutter/material.dart';

import '../components/buttons/app_button.dart';
import '../components/feedback/app_inline_message.dart';
import '../components/inputs/app_text_field.dart';
import '../components/layout/app_page_shell.dart';
import '../components/surfaces/app_section_card.dart';
import '../constants/ui_tokens.dart';

class NameEntryPage extends StatelessWidget {
  const NameEntryPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.submitLabel,
    required this.error,
    required this.nameController,
    required this.onSubmit,
    this.codeController,
  });

  final String title;
  final String subtitle;
  final bool loading;
  final String submitLabel;
  final String error;
  final TextEditingController nameController;
  final TextEditingController? codeController;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppPageShell(
        alignTop: false,
        maxContentWidth: 560,
        child: AppSectionCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF7FA3), Color(0xFFFFA88A)],
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFFFF4E8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              if (codeController != null) ...[
                AppTextField(
                  controller: codeController!,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  labelText: 'Room code',
                  hintText: 'ABC123',
                  counterText: '',
                ),
                const SizedBox(height: 12),
              ],
              AppTextField(
                controller: nameController,
                maxLength: 32,
                labelText: 'Your name',
                hintText: 'Pick Something Funny lol',
                counterText: '',
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 12),
                AppInlineMessage(message: error, color: AppColors.error),
              ],
              const SizedBox(height: 14),
              AppButton(
                onPressed: onSubmit,
                loading: loading,
                text: submitLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
