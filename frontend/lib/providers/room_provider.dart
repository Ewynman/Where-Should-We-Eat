import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../api_client.dart';
import '../constants/cuisine_constants.dart';
import '../constants/suggestion_validation.dart';
import '../models.dart';
import 'session_provider.dart';

// #region agent log
void _debugLog(String message, Map<String, dynamic> data) {
  final payload = {
    'sessionId': 'f5120d',
    'location': 'room_provider.dart',
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  Future<void>(() async {
    try {
      await http.post(
        Uri.parse(
          'http://127.0.0.1:7542/ingest/e00f7f0d-6c0b-4cee-91cd-bbfb1a502ff5',
        ),
        headers: {
          'Content-Type': 'application/json',
          'X-Debug-Session-Id': 'f5120d',
        },
        body: jsonEncode(payload),
      );
    } catch (_) {}
  });
}
// #endregion

/// Room state for a given room code. Refreshes on first watch; use [roomNotifierProvider] for actions.
final roomProvider =
    AsyncNotifierProvider.family<RoomNotifier, RoomModel?, String>(
  RoomNotifier.new,
);

/// Notifier for room actions (refresh, addOption, vote, startVoting, restart).
RoomNotifier roomNotifier(WidgetRef ref, String roomCode) {
  return ref.read(roomProvider(roomCode).notifier);
}

class RoomNotifier extends FamilyAsyncNotifier<RoomModel?, String> {
  late final String _roomCode;

  @override
  Future<RoomModel?> build(String roomCode) async {
    _roomCode = roomCode;
    return ApiClient.getRoom(roomCode);
  }

  Future<String?> _userId() async {
    return ref.read(sessionUserIdProvider).valueOrNull;
  }

  Future<void> refresh() async {
    try {
      state = AsyncData(await ApiClient.getRoom(_roomCode));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Updates room state from a WebSocket room_update (no HTTP).
  void applyRoomUpdate(RoomModel room) {
    state = AsyncData(room);
  }

  Future<void> addOption({
    required String name,
    required TextEditingController optionController,
  }) async {
    final room = state.valueOrNull;
    final userId = await _userId();
    if (room == null || userId == null) return;
    final value = name.trim();
    if (value.isEmpty || room.options.length >= 10) return;

    final validationError = validateSuggestionName(
      value: value,
      existingNames: room.options.map((e) => e.name),
    );
    if (validationError != null) {
      throw Exception(validationError);
    }
    final cuisine = inferCuisineTypeFromSuggestion(value);

    await ApiClient.addOption(_roomCode, value, userId, cuisine);
    optionController.clear();
    await refresh();
  }

  Future<void> vote(String optionId) async {
    final userId = await _userId();
    // #region agent log
    _debugLog('vote_provider', {'optionId': optionId, 'userId': userId, 'userId_is_null': userId == null});
    // #endregion
    if (userId == null) {
      throw Exception('Session not ready. Please wait or rejoin the room.');
    }
    await ApiClient.vote(_roomCode, optionId, userId);
    await refresh();
  }

  Future<void> startVoting({double lat = 37.7749, double lng = -122.4194}) async {
    final userId = await _userId();
    if (userId == null) return;
    await ApiClient.startTimer(
      roomCode: _roomCode,
      userId: userId,
      latitude: lat,
      longitude: lng,
      durationSeconds: 60,
    );
    await refresh();
  }

  Future<void> restart() async {
    final userId = await _userId();
    if (userId == null) return;
    final room = await ApiClient.restartRoom(_roomCode, userId);
    state = AsyncData(room);
  }

  Future<void> kickParticipant(String targetUsername) async {
    final userId = await _userId();
    if (userId == null) return;
    await ApiClient.kickParticipant(
      roomCode: _roomCode,
      userId: userId,
      targetUsername: targetUsername,
    );
    await refresh();
  }

  Future<void> transferHost(String newHostUsername) async {
    final userId = await _userId();
    if (userId == null) return;
    await ApiClient.transferHost(
      roomCode: _roomCode,
      userId: userId,
      newHostUsername: newHostUsername,
    );
    await refresh();
  }
}
