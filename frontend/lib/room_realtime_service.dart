import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';

/// Native WebSocket client for FastAPI `/ws/{roomId}` (room id = Mongo `_id`).
class RoomRealtimeService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;

  void connect({
    required String roomId,
    required String username,
    required void Function(String message) onKickedByHost,
    required void Function() onServerSignalRefresh,
  }) {
    disconnect();
    final base = Uri.parse(AppConfig.apiBase);
    final wsScheme = base.scheme == 'https' ? 'wss' : 'ws';
    final uri = base.replace(scheme: wsScheme, path: '/ws/$roomId');

    _channel = WebSocketChannel.connect(uri);
    _channel!.sink.add(
      jsonEncode({'type': 'join', 'username': username}),
    );

    _sub = _channel!.stream.listen(
      (raw) {
        final text = _decodeFrame(raw);
        if (text == null) return;
        Map<String, dynamic>? data;
        try {
          final decoded = jsonDecode(text);
          if (decoded is Map<String, dynamic>) {
            data = decoded;
          } else if (decoded is Map) {
            data = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          return;
        }
        if (data == null) return;
        final type = data['type']?.toString();
        if (type == 'kicked_by_host') {
          onKickedByHost(
            data['message']?.toString() ?? 'You were removed from the room.',
          );
          disconnect();
          return;
        }
        if (type == 'participants_updated' ||
            type == 'host_changed' ||
            type == 'user_joined' ||
            type == 'vote_update' ||
            type == 'voting_started' ||
            type == 'voting_ended') {
          onServerSignalRefresh();
        }
      },
      onError: (_) => disconnect(),
      onDone: () => disconnect(),
    );
  }

  String? _decodeFrame(dynamic raw) {
    if (raw is String) return raw;
    if (raw is List<int>) return utf8.decode(raw);
    return null;
  }

  void disconnect() {
    unawaited(_sub?.cancel());
    _sub = null;
    unawaited(_channel?.sink.close());
    _channel = null;
  }
}
