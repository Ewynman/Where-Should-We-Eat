import 'package:flutter/material.dart';

import 'app_text_field.dart';

class AppAutocompleteField extends StatelessWidget {
  const AppAutocompleteField({
    super.key,
    required this.externalController,
    required this.options,
    this.enabled = true,
    this.hintText,
    this.maxLength = 64,
  });

  final TextEditingController externalController;
  final List<String> options;
  final bool enabled;
  final String? hintText;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.toLowerCase().trim();
        if (query.isEmpty) return const Iterable<String>.empty();
        return options.where((option) => option.contains(query));
      },
      onSelected: (value) {
        externalController.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            if (textEditingController.text != externalController.text) {
              textEditingController.value = TextEditingValue(
                text: externalController.text,
                selection: TextSelection.collapsed(
                  offset: externalController.text.length,
                ),
              );
            }
            return AppTextField(
              controller: textEditingController,
              focusNode: focusNode,
              enabled: enabled,
              maxLength: maxLength,
              onChanged: (value) => externalController.text = value,
              counterText: '',
              hintText: hintText,
            );
          },
    );
  }
}
