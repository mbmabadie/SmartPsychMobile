// lib/core/services/health_service.dart
// ✅ محسّن: يعتمد على UnifiedTrackingService كمصدر بيانات حقيقي بدل البيانات الوهمية

import 'dart:async';
import 'package:flutter/material.dart';
import 'unified_tracking_service.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  static HealthService get instance => _instance;

  final UnifiedTrackingService _trackingService = UnifiedTrackingService.instance;

  bool _isInitialized = false;
  bool _isTracking = false;

  Future<bool> initialize() async {
    try {
      _isInitialized = true;
      debugPrint('💪 تم تهيئة HealthService');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة HealthService: $e');
      return false;
    }
  }

  Future<void> startTracking() async {
    if (!_isInitialized) {
      throw Exception('HealthService not initialized');
    }
    _isTracking = true;
    debugPrint('💪 بدء تتبع بيانات الصحة واللياقة');
  }

  Future<void> stopTracking() async {
    _isTracking = false;
    debugPrint('💪 إيقاف تتبع بيانات الصحة واللياقة');
  }

  /// الحصول على خطوات اليوم من UnifiedTrackingService
  Future<int> getTodaysSteps() async {
    try {
      final data = await _trackingService.getTodayData();
      return data['steps'] as int? ?? 0;
    } catch (e) {
      debugPrint('❌ خطأ في جلب الخطوات: $e');
      return 0;
    }
  }

  /// الحصول على مسافة اليوم
  Future<double> getTodaysDistance() async {
    try {
      final data = await _trackingService.getTodayData();
      return (data['distance'] as double?) ?? 0.0;
    } catch (e) {
      debugPrint('❌ خطأ في جلب المسافة: $e');
      return 0.0;
    }
  }

  /// الحصول على السعرات المحروقة اليوم
  Future<double> getTodaysCalories() async {
    try {
      final data = await _trackingService.getTodayData();
      return (data['calories'] as double?) ?? 0.0;
    } catch (e) {
      debugPrint('❌ خطأ في جلب السعرات: $e');
      return 0.0;
    }
  }

  bool get isTracking => _isTracking;
  bool get isInitialized => _isInitialized;
}
