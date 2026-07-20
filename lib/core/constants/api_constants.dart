import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConstants {
  // TODO: Thay bằng IP LAN thực tế của máy bạn (mở CMD gõ ipconfig -> IPv4 Address)
  // Ví dụ: '192.168.1.38'
  static const String physicalDeviceIP = '192.168.1.38';

  // TODO: Thay bằng Domain thật sau khi Deploy Backend lên Server
  static const String productionDomain = 'https://api.caffeshop.com';
  static const String cloudinaryCloudName = 'dcswvdjcn';

  /// Trả về Base URL tự động tùy thuộc vào môi trường đang chạy
  static String get baseUrl {
    // 1. Môi trường Production (Khi build Release mang đi Demo)
    if (kReleaseMode) {
      return productionDomain;
    }

    // 2. Môi trường chạy trên Web Browser (Chrome/Edge)
    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    // 3. Môi trường chạy trên Máy ảo Android (Android Emulator)
    if (Platform.isAndroid && !isPhysicalAndroidDevice()) {
      return 'http://10.0.2.2:8080';
    }

    // 4. Môi trường chạy trên Máy tính Windows/macOS/Linux
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 'http://localhost:8080';
    }

    // 5. Môi trường chạy trên Thiết bị vật lý (Cắm cáp iPhone/Android thật)
    // Thiết bị thật cần bắt chung Wifi với máy tính chứa Backend.
    return 'http://$physicalDeviceIP:8080';
  }

  static String get wsUrl {
    final base = baseUrl;
    if (base.startsWith('https://')) {
      return base.replaceFirst('https://', 'wss://');
    }
    return base.replaceFirst('http://', 'ws://');
  }

  // Tiện ích tự chế để kiểm tra xem có phải máy ảo không.
  // Gợi ý: Cài package 'device_info_plus' để check isPhysicalDevice chuẩn xác 100%.
  static bool isPhysicalAndroidDevice() {
    return false; // Mặc định giả sử là máy ảo khi code.
  }
}
