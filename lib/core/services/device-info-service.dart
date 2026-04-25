import 'dart:io';

import 'package:advertising_id/advertising_id.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Collects device context for the PATCH /users/me call on every app launch.
class DeviceInfoService {
  final _plugin = DeviceInfoPlugin();

  Future<Map<String, dynamic>> collect() async {
    return {
      'device_model': await _deviceModel(),
      'time_stamp': DateTime.now().toUtc().toIso8601String(),
      'time_zone': DateTime.now().timeZoneName,
      'IDFA': await _advertisingId(),
      'enable_noti': await _notificationEnabled(),
      'platform': Platform.isIOS ? 'IOS' : 'ANDROID',
    };
  }

  Future<String> _deviceModel() async {
    try {
      if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        return info.utsname.machine;
      } else if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        return info.model;
      }
    } catch (_) {}
    return 'unknown';
  }

  // iOS: IDFA via ATT (null if not authorized).
  // Android: GAID via Google Play Services (null if user opted out).
  Future<String?> _advertisingId() async {
    try {
      if (Platform.isIOS) {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.authorized) {
          return await AppTrackingTransparency.getAdvertisingIdentifier();
        }
        return null;
      } else if (Platform.isAndroid) {
        return await AdvertisingId.id(true);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> _notificationEnabled() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }
}
