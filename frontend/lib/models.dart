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
    final name = (json['name'] ?? json['username'] ?? 'Guest').toString();
    return RoomParticipant(
      id: (json['id'] ?? name).toString(),
      name: name,
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
    this.googleMapsUri,
    this.websiteUri,
    this.placeId,
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
  final String? googleMapsUri;
  final String? websiteUri;
  final String? placeId;

  bool get isRestaurant => source == OptionSource.restaurant;

  /// Prefer Google Maps deep link, then place id search, then name + address.
  Uri? get mapsLaunchUri {
    final g = googleMapsUri?.trim();
    if (g != null && g.isNotEmpty) {
      final u = Uri.tryParse(g);
      if (u != null) return u;
    }
    final pid = placeId?.trim();
    if (pid != null && pid.isNotEmpty) {
      return Uri.parse(
        'https://www.google.com/maps/search/?api=1&query_place_id=${Uri.encodeComponent(pid)}',
      );
    }
    final q = [name, if (address != null && address!.trim().isNotEmpty) address!.trim()]
        .join(' ');
    if (q.trim().isEmpty) return null;
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q.trim())}',
    );
  }

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    final ratingRaw = json['rating'] ?? json['avgRating'];
    final highlightsRaw =
        json['menuHighlights'] ?? json['highlights'] ?? json['menu_items'];
    final sourceRaw = (json['source'] as String? ?? 'cuisine').toLowerCase();
    final source = sourceRaw == 'restaurant'
        ? OptionSource.restaurant
        : OptionSource.cuisine;

    final name = (json['name'] ?? '').toString();
    final roomId = (json['roomId'] ?? '').toString();
    return OptionModel(
      id: (json['id'] ?? name).toString(),
      roomId: roomId,
      name: name,
      voteCount: (json['voteCount'] ?? json['votes']) as int? ?? 0,
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
      googleMapsUri:
          (json['googleMapsUri'] ?? json['google_maps_uri']) as String?,
      websiteUri: (json['websiteUri'] ?? json['website_uri']) as String?,
      placeId: (json['placeId'] ?? json['place_id']) as String?,
    );
  }
}

class RoomModel {
  RoomModel({
    required this.id,
    required this.code,
    required this.hostId,
    required this.maxCapacity,
    required this.status,
    required this.endTime,
    required this.options,
    required this.participants,
    this.placesError,
  });

  final String id;
  final String code;
  final String hostId;
  final int maxCapacity;
  final RoomStatus status;
  final DateTime? endTime;
  final List<OptionModel> options;
  final List<RoomParticipant> participants;
  final String? placesError;

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
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      hostId: (json['hostId'] ?? '').toString(),
      maxCapacity: (json['maxCapacity'] as num?)?.toInt() ?? 20,
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
      placesError: (json['placesError'] ?? json['places_error']) as String?,
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
