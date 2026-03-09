enum RoomStatus {
  waiting,
  /// Backward compat: old backend returns "voting" for first phase.
  voting,
  cuisineVoting,
  fetchingRestaurants,
  restaurantVoting,
  finished;

  /// For status chip and labels.
  String get displayName {
    return switch (this) {
      RoomStatus.waiting => 'waiting',
      RoomStatus.voting => 'voting',
      RoomStatus.cuisineVoting => 'cuisine voting',
      RoomStatus.fetchingRestaurants => 'finding restaurants',
      RoomStatus.restaurantVoting => 'restaurant voting',
      RoomStatus.finished => 'finished',
    };
  }
}

class RoomParticipant {
  RoomParticipant({
    required this.id,
    required this.name,
    required this.hasVoted,
  });

  final String id;
  final String name;
  final bool hasVoted;

  factory RoomParticipant.fromJson(Map<String, dynamic> json) {
    return RoomParticipant(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Guest',
      hasVoted: json['hasVoted'] as bool? ?? false,
    );
  }
}

enum OptionSource { cuisine, restaurant }

class OptionModel {
  OptionModel({
    required this.id,
    required this.roomId,
    required this.name,
    required this.voteCount,
    this.address,
    this.imageUrl,
    this.cuisineType,
    this.rating,
    this.menuHighlights = const [],
    this.source = OptionSource.cuisine,
  });

  final String id;
  final String roomId;
  final String name;
  final int voteCount;
  final String? address;
  final String? imageUrl;
  final String? cuisineType;
  final double? rating;
  final List<String> menuHighlights;
  final OptionSource source;

  bool get isRestaurant => source == OptionSource.restaurant;

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    final ratingRaw = json['rating'] ?? json['avgRating'];
    final highlightsRaw =
        json['menuHighlights'] ?? json['highlights'] ?? json['menu_items'];
    final sourceRaw = (json['source'] as String? ?? 'cuisine').toLowerCase();
    final source = sourceRaw == 'restaurant'
        ? OptionSource.restaurant
        : OptionSource.cuisine;

    return OptionModel(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      name: json['name'] as String,
      voteCount: json['voteCount'] as int? ?? 0,
      address: json['address'] as String?,
      imageUrl: (json['imageUrl'] ?? json['image_url']) as String?,
      cuisineType: (json['cuisineType'] ?? json['cuisine_type']) as String?,
      rating: ratingRaw is num
          ? ratingRaw.toDouble()
          : double.tryParse(ratingRaw?.toString() ?? ''),
      menuHighlights: highlightsRaw is List
          ? highlightsRaw.map((item) => item.toString()).toList()
          : const [],
      source: source,
    );
  }
}

class RoomModel {
  RoomModel({
    required this.id,
    required this.code,
    required this.hostId,
    required this.status,
    required this.endTime,
    required this.options,
    required this.participants,
  });

  final String id;
  final String code;
  final String hostId;
  final RoomStatus status;
  final DateTime? endTime;
  final List<OptionModel> options;
  final List<RoomParticipant> participants;

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    final statusRaw = (json['status'] as String? ?? 'waiting').toLowerCase();
    final status = switch (statusRaw) {
      'cuisine_voting' => RoomStatus.cuisineVoting,
      'fetching_restaurants' => RoomStatus.fetchingRestaurants,
      'restaurant_voting' => RoomStatus.restaurantVoting,
      'voting' => RoomStatus.cuisineVoting,
      'finished' => RoomStatus.finished,
      _ => RoomStatus.waiting,
    };

    return RoomModel(
      id: json['id'] as String,
      code: json['code'] as String,
      hostId: json['hostId'] as String,
      status: status,
      endTime: json['endTime'] == null
          ? null
          : DateTime.tryParse(json['endTime'] as String),
      options: (json['options'] as List<dynamic>? ?? [])
          .map((item) => OptionModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((item) => RoomParticipant.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UserModel {
  UserModel({required this.id, required this.name});

  final String id;
  final String name;
}

class RoomJoinResult {
  RoomJoinResult({required this.room, required this.user});

  final RoomModel room;
  final UserModel user;
}
