import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../components/chips/app_status_chip.dart';
import '../components/layout/app_page_shell.dart';
import '../models.dart';
import '../providers/room_provider.dart';
import '../providers/session_provider.dart';
import '../room_realtime_service.dart';
import '../widgets/cuisine_voting_section.dart';
import '../widgets/error_banner.dart';
import '../widgets/fetching_restaurants_section.dart';
import '../widgets/phase_transition_overlay.dart';
import '../widgets/results_section.dart';
import '../widgets/voting_section.dart';
import '../widgets/waiting_section.dart';

class RoomPage extends ConsumerStatefulWidget {
  const RoomPage({super.key, required this.roomCode});

  final String roomCode;

  @override
  ConsumerState<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends ConsumerState<RoomPage> {
  final _optionController = TextEditingController();
  final _roomRealtime = RoomRealtimeService();
  Timer? _pollingTimer;
  String _error = '';
  bool _realtimeConnected = false;
  String? _votedOptionId;
  String? _highlightedOptionId;
  Set<String> _knownOptionIds = {};
  bool _addingOption = false;
  bool _startingVote = false;
  RoomStatus? _phaseOverlayStatus;
  /// So we only show the phase overlay once per phase (not again on every poll).
  RoomStatus? _lastPhaseOverlayShown;
  /// Prevents clearing _votedOptionId more than once per restaurant phase.
  bool _clearedVoteForRestaurantPhase = false;
  ProviderSubscription<AsyncValue<String?>>? _sessionSub;

  static const _phaseOverlayStatuses = [
    RoomStatus.cuisineVoting,
    RoomStatus.voting,
    RoomStatus.fetchingRestaurants,
    RoomStatus.restaurantVoting,
  ];

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

  @override
  void initState() {
    super.initState();
    _sessionSub = ref.listenManual(sessionUserIdProvider, (prev, next) {
      final uid = next.valueOrNull;
      if (uid == null || uid.isEmpty || _realtimeConnected) return;
      _realtimeConnected = true;
      _roomRealtime.connect(
        roomId: widget.roomCode,
        username: uid,
        onKickedByHost: _onKickedByHost,
        onServerSignalRefresh: () {
          unawaited(roomNotifier(ref, widget.roomCode).refresh());
        },
      );
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _sessionSub?.close();
    _roomRealtime.disconnect();
    _pollingTimer?.cancel();
    _optionController.dispose();
    super.dispose();
  }

  void _onKickedByHost(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Removed from room'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).maybePop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _hostKick(String username) async {
    try {
      await roomNotifier(ref, widget.roomCode).kickParticipant(username);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _hostTransfer(String username) async {
    try {
      await roomNotifier(ref, widget.roomCode).transferHost(username);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showParticipantsSheet(RoomModel room, bool isHost, String? userId) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'People in this room',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            for (final p in room.participants)
              ListTile(
                title: Text(p.name),
                subtitle: p.name == room.hostId
                    ? const Text('Host')
                    : null,
                trailing: isHost && p.name != userId
                    ? Wrap(
                        alignment: WrapAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              try {
                                await roomNotifier(ref, widget.roomCode)
                                    .kickParticipant(p.name);
                                if (sheetCtx.mounted) {
                                  Navigator.of(sheetCtx).pop();
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() => _error =
                                      e.toString().replaceFirst('Exception: ', ''));
                                }
                              }
                            },
                            child: const Text('Kick'),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                await roomNotifier(ref, widget.roomCode)
                                    .transferHost(p.name);
                                if (sheetCtx.mounted) {
                                  Navigator.of(sheetCtx).pop();
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() => _error =
                                      e.toString().replaceFirst('Exception: ', ''));
                                }
                              }
                            },
                            child: const Text('Make host'),
                          ),
                        ],
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  void _configurePolling(RoomModel? room) {
    _pollingTimer?.cancel();
    if (room == null) return;
    if (room.status == RoomStatus.waiting ||
        room.status == RoomStatus.voting ||
        room.status == RoomStatus.cuisineVoting ||
        room.status == RoomStatus.restaurantVoting ||
        room.status == RoomStatus.fetchingRestaurants) {
      _pollingTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => roomNotifier(ref, widget.roomCode).refresh(),
      );
    }
  }

  void _applyRoomUpdate(RoomModel room) {
    final nextIds = room.options.map((e) => e.id).toSet();
    final added = nextIds.difference(_knownOptionIds);
    setState(() {
      _error = '';
      _highlightedOptionId = added.isNotEmpty ? added.first : null;
      _knownOptionIds = nextIds;
    });
  }

  Future<void> _addOption() async {
    final room = ref.read(roomProvider(widget.roomCode)).valueOrNull;
    if (room == null) return;
    final value = _optionController.text.trim();
    if (value.isEmpty) return;

    setState(() => _addingOption = true);
    try {
      await roomNotifier(ref, widget.roomCode).addOption(
        name: value,
        optionController: _optionController,
      );
      final next = ref.read(roomProvider(widget.roomCode)).valueOrNull;
      if (next != null) _applyRoomUpdate(next);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _addingOption = false);
    }
  }

  Future<void> _vote(String optionId) async {
    if (_votedOptionId != null) return;
    setState(() => _votedOptionId = optionId);
    try {
      await roomNotifier(ref, widget.roomCode).vote(optionId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _votedOptionId = null;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
      return;
    }
    final next = ref.read(roomProvider(widget.roomCode)).valueOrNull;
    if (next != null) _applyRoomUpdate(next);
  }

  Future<void> _startVoting() async {
    if (_startingVote) return;
    setState(() => _startingVote = true);
    try {
      final coords = await _resolveLocation();
      await roomNotifier(ref, widget.roomCode).startVoting(
        latitude: coords.latitude,
        longitude: coords.longitude,
      );
      if (!mounted) return;
      setState(() {
        _phaseOverlayStatus = RoomStatus.cuisineVoting;
        _lastPhaseOverlayShown = RoomStatus.cuisineVoting;
      });
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _startingVote = false);
    }
  }

  Future<void> _restart() async {
    try {
      await roomNotifier(ref, widget.roomCode).restart();
      if (!mounted) return;
      setState(() {
        _votedOptionId = null;
        _highlightedOptionId = null;
        _clearedVoteForRestaurantPhase = false;
        final room = ref.read(roomProvider(widget.roomCode)).valueOrNull;
        _knownOptionIds = room?.options.map((e) => e.id).toSet() ?? {};
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomProvider(widget.roomCode));
    final userIdAsync = ref.watch(sessionUserIdProvider);

    return roomAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(
          child: Text(err.toString().replaceFirst('Exception: ', '')),
        ),
      ),
      data: (room) {
        if (room == null) {
          return Scaffold(
            body: Center(
              child: Text(_error.isEmpty ? 'Room not found' : _error),
            ),
          );
        }

        _configurePolling(room);
        // Reset voted state only when we're definitely in restaurant phase with restaurant options,
        // so the user can vote again; only clear once per transition to avoid affecting cuisine.
        final isRestaurantPhase = room.status == RoomStatus.restaurantVoting &&
            room.options.any((o) => o.isRestaurant);
        if (!isRestaurantPhase) {
          _clearedVoteForRestaurantPhase = false;
        } else if (!_clearedVoteForRestaurantPhase &&
            _votedOptionId != null &&
            !room.options.any((o) => o.id == _votedOptionId)) {
          _clearedVoteForRestaurantPhase = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _votedOptionId = null);
          });
        }
        final userId = userIdAsync.valueOrNull;
        final isHost = userId == room.hostId;
        final winner = room.status == RoomStatus.finished &&
                room.options.isNotEmpty
            ? _pickWinner(room.options)
            : null;
        final sortedResults = [...room.options]
          ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

        if (_phaseOverlayStatuses.contains(room.status) &&
            _lastPhaseOverlayShown != room.status) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _phaseOverlayStatus = room.status;
              _lastPhaseOverlayShown = room.status;
            });
          });
        }
        if (!_phaseOverlayStatuses.contains(room.status)) {
          _phaseOverlayStatus = null;
          _lastPhaseOverlayShown = null;
        }

        final overlayColor = _phaseOverlayStatus == null
            ? const Color(0xFFEBD6FB)
            : switch (_phaseOverlayStatus!) {
                RoomStatus.cuisineVoting => const Color(0xFFEBD6FB),
                RoomStatus.fetchingRestaurants => const Color(0xFFBADFDB),
                RoomStatus.restaurantVoting => const Color(0xFFFFBDBD),
                _ => const Color(0xFFEBD6FB),
              };

        final appBarColor = _phaseOverlayStatus != null
            ? overlayColor
            : const Color(0xFFFCF9EA);

        if (_phaseOverlayStatus != null) {
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: overlayColor,
              statusBarIconBrightness: Brightness.dark,
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: appBarColor,
            title: Text('Room ${room.code}'),
            actions: [
              if (isHost)
                IconButton(
                  tooltip: 'People',
                  icon: const Icon(Icons.group_outlined),
                  onPressed: () =>
                      _showParticipantsSheet(room, isHost, userId),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AppStatusChip(label: room.status.displayName),
              ),
            ],
          ),
          body: Stack(
            children: [
              AppPageShell(
                maxContentWidth: 760,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: RefreshIndicator(
                  onRefresh: () => roomNotifier(ref, widget.roomCode).refresh(),
                  child: ListView(
                    children: [
                      if (_error.isNotEmpty) ErrorBanner(message: _error),
                      if (room.placesError != null &&
                          room.placesError!.trim().isNotEmpty)
                        ErrorBanner(
                          message:
                              'Restaurant search: ${room.placesError!.trim()}',
                        ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _buildSectionForStatus(
                          room: room,
                          isHost: isHost,
                          winner: winner,
                          sortedResults: sortedResults,
                          userId: userId,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_phaseOverlayStatus != null)
                Positioned.fill(
                  child: PhaseTransitionOverlay(
                    label: _phaseOverlayStatus!.displayName,
                    color: overlayColor,
                    onDismiss: () {
                      if (mounted) {
                        SystemChrome.setSystemUIOverlayStyle(
                          const SystemUiOverlayStyle(
                            statusBarColor: Color(0xFFFCF9EA),
                            statusBarIconBrightness: Brightness.dark,
                          ),
                        );
                        setState(() => _phaseOverlayStatus = null);
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionForStatus({
    required RoomModel room,
    required bool isHost,
    required OptionModel? winner,
    required List<OptionModel> sortedResults,
    required String? userId,
  }) {
    if (room.status == RoomStatus.waiting) {
      return WaitingSection(
        key: const ValueKey('waiting-section'),
        room: room,
        isHost: isHost,
        currentUserId: userId,
        highlightedOptionId: _highlightedOptionId,
        optionController: _optionController,
        addingOption: _addingOption,
        startingVote: _startingVote,
        onAddOption: _addOption,
        onStartVoting: _startVoting,
        onKickParticipant: isHost ? _hostKick : null,
        onTransferHost: isHost ? _hostTransfer : null,
      );
    }
    if (room.status == RoomStatus.cuisineVoting || room.status == RoomStatus.voting) {
      return CuisineVotingSection(
        key: const ValueKey('cuisine-voting-section'),
        room: room,
        votedOptionId: _votedOptionId,
        onVote: _vote,
        onCountdownDone: () => roomNotifier(ref, widget.roomCode).refresh(),
      );
    }
    if (room.status == RoomStatus.fetchingRestaurants) {
      return FetchingRestaurantsSection(
        key: const ValueKey('fetching-section'),
        onRefresh: () => roomNotifier(ref, widget.roomCode).refresh(),
      );
    }
    if (room.status == RoomStatus.restaurantVoting) {
      return VotingSection(
        key: const ValueKey('restaurant-voting-section'),
        room: room,
        votedOptionId: _votedOptionId,
        onVote: _vote,
        onCountdownDone: () => roomNotifier(ref, widget.roomCode).refresh(),
      );
    }
    return ResultsSection(
      key: const ValueKey('results-section'),
      winner: winner,
      sortedResults: sortedResults,
      isHost: isHost,
      onRestart: _restart,
    );
  }

  OptionModel _pickWinner(List<OptionModel> options) {
    final maxVotes = options.map((e) => e.voteCount).reduce(max);
    final top = options.where((e) => e.voteCount == maxVotes).toList();
    return top[Random().nextInt(top.length)];
  }
}
