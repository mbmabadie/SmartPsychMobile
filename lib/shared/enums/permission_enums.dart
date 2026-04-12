// lib/shared/enums/permission_enums.dart
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

/// حالات الإذن
enum PermissionState {
  pending,
  requesting,
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  provisional,
}

/// بيانات الإذن
class PermissionData {
  final String key;
  final Permission permission;
  final IconData icon;
  final String titleKey;
  final String descriptionKey;
  final bool isEssential;

  const PermissionData({
    required this.key,
    required this.permission,
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
    required this.isEssential,
  });
}