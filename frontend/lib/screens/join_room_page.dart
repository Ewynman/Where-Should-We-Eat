import 'package:flutter/material.dart';

import '../api_client.dart';
import '../session.dart';
import 'name_entry_page.dart';

class JoinRoomPage extends StatefulWidget {
  const JoinRoomPage({super.key});

  @override
  State<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends State<JoinRoomPage> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    if (code.isEmpty || name.isEmpty) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final result = await ApiClient.joinRoom(code, name);
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
    return NameEntryPage(
      title: 'Join Room',
      subtitle: 'Enter your room code and jump into voting.',
      loading: _loading,
      submitLabel: 'Join Room',
      error: _error,
      codeController: _codeController,
      nameController: _nameController,
      onSubmit: _submit,
    );
  }
}
