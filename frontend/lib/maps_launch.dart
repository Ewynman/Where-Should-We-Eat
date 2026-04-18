import 'package:url_launcher/url_launcher.dart';

import 'models.dart';

Future<bool> launchOptionInMaps(OptionModel option) async {
  final uri = option.mapsLaunchUri;
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> launchWebsite(String? raw) async {
  if (raw == null || raw.trim().isEmpty) return false;
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
