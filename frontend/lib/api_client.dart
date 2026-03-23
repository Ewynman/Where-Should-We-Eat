import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class AppConfig {
  static const apiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  static const wsBase = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: apiBase,
  );
}

class ApiClient {
  static Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBase}$path');
    const headers = {'Content-Type': 'application/json'};

    late final http.Response response;
    if (method == 'POST') {
      response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body ?? <String, dynamic>{}),
      );
    } else {
      response = await http.get(uri, headers: headers);
    }

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = decoded is Map<String, dynamic>
          ? decoded['detail']?.toString() ?? 'Request failed'
          : 'Request failed';
      throw Exception(detail);
    }

    return decoded;
  }

  static Future<RoomJoinResult> createRoom(
    String name, {
    required double latitude,
    required double longitude,
  }) async {
    final data = await _request(
      'POST',
      '/create-room',
      body: {
        'host_name': name,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    final map = data as Map<String, dynamic>;
    final roomId = map['room_id']?.toString() ?? '';
    final room = await getRoom(roomId);
    return RoomJoinResult(
      room: room,
      user: UserModel(id: name, name: name),
    );
  }

  static Future<RoomJoinResult> joinRoom(String code, String name) async {
    final data = await _request('POST', '/join-room', body: {
      'code': code.trim().toUpperCase(),
      'username': name,
    });
    final map = data as Map<String, dynamic>;
    return RoomJoinResult(
      room: RoomModel.fromJson({
        '_id': map['room_id'],
        'code': map['code'],
        'hostId': '',
        'status': 'waiting',
        'options': map['restaurants'] ?? [],
        'participants': map['participants'] ?? [],
      }),
      user: UserModel(id: name, name: name),
    );
  }

  static Future<RoomModel> getRoom(String roomCode) async {
    final data = await _request('GET', '/room/$roomCode');
    return RoomModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> addOption(
    String roomCode,
    String name,
    String userId,
    String cuisineType,
  ) async {
    await _request(
      'POST',
      '/api/rooms/$roomCode/options',
      body: {'name': name, 'userId': userId, 'cuisineType': cuisineType},
    );
  }

  static Future<void> vote(
    String roomCode,
    String optionId,
    String userId,
  ) async {
    await _request(
      'POST',
      '/api/rooms/$roomCode/vote',
      body: {'optionId': optionId, 'userId': userId},
    );
  }

  static Future<void> startTimer({
    required String roomCode,
    required String userId,
    required double latitude,
    required double longitude,
    int durationSeconds = 60,
  }) async {
    await _request(
      'POST',
      '/api/rooms/$roomCode/start',
      body: {
        'userId': userId,
        'durationSeconds': durationSeconds,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  static Future<RoomModel> restartRoom(String roomCode, String userId) async {
    final data = await _request(
      'POST',
      '/api/rooms/$roomCode/restart',
      body: {'userId': userId},
    );
    return RoomModel.fromJson(data as Map<String, dynamic>);
  }
}
