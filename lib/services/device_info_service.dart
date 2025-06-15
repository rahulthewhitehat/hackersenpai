import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  // Get unique device ID across platforms
  Future<String> getUniqueDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        // Use serialNumber as the primary identifier
        // Fall back to androidId if serialNumber is not available
        if (androidInfo.serialNumber.isNotEmpty &&
            androidInfo.serialNumber != 'unknown') {
          return androidInfo.serialNumber;
        } else {
          // Combine multiple identifiers to create a more reliable ID
          return '${androidInfo.id}_${androidInfo.model}_${androidInfo.brand}';
        }
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfoPlugin.windowsInfo;
        // Combine computerName and buildNumber for a unique identifier
        // systemUuid may not be available without elevated permissions
        if (windowsInfo.computerName.isNotEmpty) {
          return '${windowsInfo.computerName}_${windowsInfo.buildNumber}_${windowsInfo.productId}';
        } else {
          // Fallback to a combination of other properties
          return 'windows_${windowsInfo.buildNumber}_${windowsInfo.productId}';
        }
      }
      return 'unknown_platform';
    } catch (e) {
      // Provide a fallback device ID in case of errors
      return 'fallback_device_id_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}