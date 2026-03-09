import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../components/chips/app_status_chip.dart';
import '../components/layout/app_page_shell.dart';
import '../models.dart';
import '../providers/room_provider.dart';
import '../providers/session_provider.dart';
import '../providers/socket_provider.dart';
import '../widgets/cuisine_voting_section.dart';
import '../widgets/error_banner.dart';
import '../widgets/fetching_restaurants_section.dart';
import '../widgets/phase_transition_overlay.dart';
import '../widgets/results_section.dart';
import '../widgets/voting_section.dart';
import '../widgets/waiting_section.dart';

// #region agent log
void _debugLog(String message, Map<String, dynamic> data) {
  final payload = {
    'sessionId': 'f5120d',
    'location': 'room_page.dart',
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  http
      .post(
        Uri.parse(
          'http://127.0.0.1:7542/ingest/e00f7f0d-6c0b-4cee-91cd-bbfb1a502ff5',
        ),
        headers: {
          'Content-Type': 'application/json',
          'X-Debug-Session-Id': 'f5120d',
        },
        body: jsonEncode(payload),
      )
      .catchError((_) {});
}
// #endregion

class RoomPage extends ConsumerStatefulWidget {
  const RoomPage({super.key, required this.roomCode});

  final String roomCode;

  @override
  ConsumerState<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends ConsumerState<RoomPage> {
  final _optionController = TextEditingController();
  Timer? _pollingTimer;
  String _error = '';
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

  static const _phaseOverlayStatuses = [
    RoomStatus.cuisineVoting,
    RoomStatus.voting,
    RoomStatus.fetchingRestaurants,
    RoomStatus.restaurantVoting,
  ];

  @override
  void initState() {
    super.initState();
    final socket = ref.read(socketServiceProvider);
    socket.connect(
      roomCode: widget.roomCode,
      onRoomUpdate: (room) {
        roomNotifier(ref, widget.roomCode).applyRoomUpdate(room);
        if (mounted) _applyRoomUpdate(room);
      },
    );
  }

  @override
  void dispose() {
    ref.read(socketServiceProvider).leave(widget.roomCode);
    _pollingTimer?.cancel();
    _optionController.dispose();
    super.dispose();
  }

  void _configurePolling(RoomModel? room) {
    _pollingTimer?.cancel();
    if (room == null) return;
    if (room.status == RoomStatus.voting ||
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
    // #region agent log
    _debugLog('room_page_vote', {'optionId': optionId, 'votedOptionId_before': _votedOptionId});
    // #endregion
    if (_votedOptionId != null) return;
    setState(() => _votedOptionId = optionId);
    try {
      await roomNotifier(ref, widget.roomCode).vote(optionId);
    } catch (e) {
      // #region agent log
      _debugLog('room_page_vote_catch', {'optionId': optionId, 'error': e.toString()});
      // #endregion
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
    setState(() {
      _startingVote = true;
      _phaseOverlayStatus = RoomStatus.cuisineVoting;
      _lastPhaseOverlayShown = RoomStatus.cuisineVoting;
    });
    try {
      await roomNotifier(ref, widget.roomCode).startVoting();
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
