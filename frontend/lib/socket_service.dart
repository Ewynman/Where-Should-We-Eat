import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_client.dart';
import 'models.dart';

class SocketService {
  io.Socket? _socket;
  String? _currentRoomCode;
  void Function(RoomModel room)? _onRoomUpdate;

  void connect({
    required String roomCode,
    required void Function(RoomModel room) onRoomUpdate,
  }) {
    _currentRoomCode = roomCode.toUpperCase();
    _onRoomUpdate = onRoomUpdate;

    _socket ??= io.io(
      AppConfig.wsBase,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(5)
          .build(),
    );

    _socket!.emit('join_room', _currentRoomCode);
    _socket!.off('room_update');
    _socket!.on('room_update', (payload) {
      if (payload is! Map) {
        return;
      }
      final map = Map<String, dynamic>.from(payload);
      final roomRaw = map['room'];
      if (roomRaw is! Map) {
        return;
      }
      _onRoomUpdate?.call(RoomModel.fromJson(Map<String, dynamic>.from(roomRaw)));
    });
    _socket!.onConnect((_) {
      if (_currentRoomCode != null) {
        _socket!.emit('join_room', _currentRoomCode);
      }
    });
  }

  void leave(String roomCode) {
    final code = roomCode.toUpperCase();
    _socket?.emit('leave_room', code);
    if (_currentRoomCode == code) {
      _currentRoomCode = null;
      _onRoomUpdate = null;
    }
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    _currentRoomCode = null;
    _onRoomUpdate = null;
  }
}
