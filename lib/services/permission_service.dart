import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<void> requestStartupPermissions() async {
    await [
      Permission.location,
      Permission.notification,
    ].request();
  }

  Future<bool> ensureLocationPermission() async {
    var status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      throw Exception('Location permission permanently denied');
    }

    throw Exception('Location permission denied');
  }

  Future<bool> ensureNotificationPermission() async {
    var status = await Permission.notification.status;

    if (status.isDenied) {
      status = await Permission.notification.request();
    }

    if (status.isGranted || status.isLimited || status.isProvisional) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      throw Exception('Notification permission permanently denied');
    }

    return false;
  }
}
