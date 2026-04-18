import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../api_client.dart';
import '../components/buttons/app_button.dart';
import '../components/feedback/app_inline_message.dart';
import '../components/inputs/app_text_field.dart';
import '../components/layout/app_page_shell.dart';
import '../components/surfaces/app_section_card.dart';
import '../constants/ui_tokens.dart';
import '../session.dart';

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  static const _createRoomHeroTag = 'create-room-cta';
  final _nameController = TextEditingController();
  bool _loading = false;
  String _error = '';
  double _maxCapacity = 10;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Same fallback as [RoomNotifier.startVoting] when GPS is unavailable.
  static const _fallbackLat = 37.7749;
  static const _fallbackLng = -122.4194;

  Future<({double latitude, double longitude})> _resolveLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (latitude: _fallbackLat, longitude: _fallbackLng);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (latitude: _fallbackLat, longitude: _fallbackLng);
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      return (latitude: pos.latitude, longitude: pos.longitude);
    } catch (_) {
      return (latitude: _fallbackLat, longitude: _fallbackLng);
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final coords = await _resolveLocation();
      final result = await ApiClient.createRoom(
        _nameController.text.trim(),
        latitude: coords.latitude,
        longitude: coords.longitude,
        maxCapacity: _maxCapacity.round(),
      );
      await UserSession.saveUser(result.user);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/room',
        arguments: result.room.id,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Room')),
      body: AppPageShell(
        maxContentWidth: 640,
        child: ListView(
          children: [
            Hero(
              tag: _createRoomHeroTag,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentPink,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFA4A4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.add_business_rounded,
                        size: 22,
                        color: Color(0xFF5F3A47),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Create Room',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Start a room and invite others with a code.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Your name',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _nameController,
                    maxLength: 32,
                    hintText: 'Pick Something Funny lol',
                    counterText: '',
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Max participants',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_maxCapacity.round()} people (including you)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5F3A47),
                    ),
                  ),
                  Slider(
                    value: _maxCapacity,
                    min: 2,
                    max: 20,
                    divisions: 18,
                    label: '${_maxCapacity.round()}',
                    onChanged: (v) => setState(() => _maxCapacity = v),
                  ),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    AppInlineMessage(message: _error, color: AppColors.error),
                  ],
                  const SizedBox(height: 16),
                  AppButton(
                    onPressed: _submit,
                    icon: Icons.arrow_forward_rounded,
                    loading: _loading,
                    text: 'Create Room',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
