const personNameOnlyBlocklist = {
  'edward',
  'eddie',
  'alex',
  'sam',
  'john',
  'mike',
  'david',
  'chris',
  'james',
  'josh',
  'matt',
  'emma',
  'olivia',
  'sophia',
  'ava',
  'isabella',
  'mia',
  'mom',
  'dad',
  'daddy',
};

String funnyNotFoodError(String value) {
  return "yeah umm you can't eat '$value', so try again and maybe something more edible.";
}

String? validateSuggestionName({
  required String value,
  required Iterable<String> existingNames,
  int minLen = 3,
  int maxLen = 64,
}) {
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  final compactLetters = normalized.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  final lowered = normalized.toLowerCase();

  if (normalized.length < minLen) return funnyNotFoodError(normalized);
  if (normalized.length > maxLen) {
    return 'that one is a little long. keep it under $maxLen characters.';
  }
  if (compactLetters.isEmpty) return funnyNotFoodError(normalized);
  if (compactLetters.split('').toSet().length == 1) {
    return funnyNotFoodError(normalized);
  }
  if (personNameOnlyBlocklist.contains(lowered)) {
    return funnyNotFoodError(normalized);
  }

  final duplicate = existingNames.any((name) => name.trim().toLowerCase() == lowered);
  if (duplicate) {
    return "'$normalized' is already on the list. pick another tasty option.";
  }

  return null;
}
