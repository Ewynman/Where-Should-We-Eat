import 'package:geolocator/geolocator.dart';

import 'session.dart';

class PermissionSnapshot {
  const PermissionSnapshot({
    required this.prompted,
    required this.granted,
    required this.serviceEnabled,
    required this.systemPermission,
  });

  final bool prompted;
  final bool granted;
  final bool serviceEnabled;
  final LocationPermission systemPermission;
}

class PermissionResult {
  const PermissionResult({
    required this.granted,
    required this.prompted,
    required this.message,
    required this.snapshot,
  });

  final bool granted;
  final bool prompted;
  final String message;
  final PermissionSnapshot snapshot;
}

class LocationPermissionService {
  static Future<PermissionSnapshot> snapshot() async {
    final prompted = await UserSession.locationPermissionPrompted();
    final grantedFlag = await UserSession.locationPermissionGranted();
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    final granted = _isGranted(permission) && grantedFlag;

    return PermissionSnapshot(
      prompted: prompted,
      granted: granted,
      serviceEnabled: serviceEnabled,
      systemPermission: permission,
    );
  }

  static Future<PermissionResult> ensurePermissionFlow() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await UserSession.setLocationPermissionPrompted(true);
      await UserSession.setLocationPermissionGranted(false);
      final state = await snapshot();
      return PermissionResult(
        granted: false,
        prompted: true,
        message: 'Location services are turned off on this device.',
        snapshot: state,
      );
    }

    var permission = await Geolocator.checkPermission();
    var prompted = await UserSession.locationPermissionPrompted();

    if (permission == LocationPermission.denied) {
      prompted = true;
      permission = await Geolocator.requestPermission();
    } else if (permission == LocationPermission.deniedForever) {
      prompted = true;
    }

    final granted = _isGranted(permission);
    await UserSession.setLocationPermissionPrompted(prompted);
    await UserSession.setLocationPermissionGranted(granted);

    final state = await snapshot();
    if (granted) {
      return PermissionResult(
        granted: true,
        prompted: prompted,
        message: 'Location permission granted.',
        snapshot: state,
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return PermissionResult(
        granted: false,
        prompted: prompted,
        message:
            'Location permission is denied forever. Open Settings to allow it.',
        snapshot: state,
      );
    }

    return PermissionResult(
      granted: false,
      prompted: prompted,
      message: 'Location permission is required to find nearby restaurants.',
      snapshot: state,
    );
  }

  static bool _isGranted(LocationPermission permission) {
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
