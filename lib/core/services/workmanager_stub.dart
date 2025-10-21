import 'package:flutter/foundation.dart';

// Stub implementation for web platform to avoid compilation errors
class Workmanager {
  static Workmanager? _instance;

  static Workmanager get instance => _instance ??= Workmanager._();

  Workmanager._();

  factory Workmanager() => instance;

  Future<void> initialize(Function callback,
      {bool isInDebugMode = false}) async {
    // No-op for web platform
    debugPrint('Workmanager not supported on web platform');
  }

  Future<void> executeTask(Function(String, Map<String, dynamic>?) task) async {
    // No-op for web platform
  }

  Future<void> registerOneOffTask(String uniqueName, String taskName,
      {Map<String, dynamic>? inputData}) async {
    // No-op for web platform
  }

  Future<void> registerPeriodicTask(String uniqueName, String taskName,
      {Duration? frequency, Map<String, dynamic>? inputData}) async {
    // No-op for web platform
  }

  Future<void> cancelByUniqueName(String uniqueName) async {
    // No-op for web platform
  }

  Future<void> cancelAll() async {
    // No-op for web platform
  }
}
