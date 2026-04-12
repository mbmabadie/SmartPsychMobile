// lib/features/sleep/tabs/history_tab.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../core/database/models/sleep_models.dart';
import '../../../shared/theme/app_colors.dart';
import '../widgets/history/sleep_session_card.dart';
import '../widgets/history/history_filters.dart';
import '../screens/sleep_detail_screen.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({Key? key}) : super(key: key);

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String _selectedQualityFilter = 'الكل';
  String _selectedDurationFilter = 'الكل';
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepTrackingProvider>(
      builder: (context, provider, _) {
        var sessions = provider.state.recentSessions;

        // تطبيق الفلاتر
        sessions = _applyFilters(sessions);

        return Column(
          children: [
            // الفلاتر
            HistoryFilters(
              selectedQualityFilter: _selectedQualityFilter,
              selectedDurationFilter: _selectedDurationFilter,
              dateRange: _dateRange,
              onQualityFilterChanged: (value) {
                setState(() => _selectedQualityFilter = value);
              },
              onDurationFilterChanged: (value) {
                setState(() => _selectedDurationFilter = value);
              },
              onDateRangeChanged: (range) {
                setState(() => _dateRange = range);
              },
              onClearFilters: () {
                setState(() {
                  _selectedQualityFilter = 'الكل';
                  _selectedDurationFilter = 'الكل';
                  _dateRange = null;
                });
              },
            ),

            // القائمة
            Expanded(
              child: sessions.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: () => provider.refreshData(),
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: sessions.length + 1,
                  itemBuilder: (context, index) {
                    if (index == sessions.length) {
                      return _buildLoadMoreButton(provider);
                    }

                    final session = sessions[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: SleepSessionCard(
                        session: session,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SleepDetailScreen(
                                session: session,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<SleepSession> _applyFilters(List<SleepSession> sessions) {
    var filtered = sessions;

    // فلتر الجودة
    if (_selectedQualityFilter != 'الكل') {
      filtered = filtered.where((session) {
        final quality = session.qualityScore ?? 0;
        switch (_selectedQualityFilter) {
          case 'ممتاز':
            return quality >= 8;
          case 'جيد':
            return quality >= 6 && quality < 8;
          case 'متوسط':
            return quality >= 4 && quality < 6;
          case 'ضعيف':
            return quality < 4;
          default:
            return true;
        }
      }).toList();
    }

    // فلتر المدة
    if (_selectedDurationFilter != 'الكل') {
      filtered = filtered.where((session) {
        final hours = session.duration?.inHours ?? 0;
        switch (_selectedDurationFilter) {
          case 'أكثر من 8 ساعات':
            return hours >= 8;
          case '6-8 ساعات':
            return hours >= 6 && hours < 8;
          case '4-6 ساعات':
            return hours >= 4 && hours < 6;
          case 'أقل من 4 ساعات':
            return hours < 4;
          default:
            return true;
        }
      }).toList();
    }

    // فلتر التاريخ
    if (_dateRange != null) {
      filtered = filtered.where((session) {
        return session.startTime.isAfter(_dateRange!.start) &&
            session.startTime.isBefore(_dateRange!.end.add(Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: Icon(
              Icons.bedtime_outlined,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'لا توجد سجلات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'سيتم عرض سجل نومك هنا',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              DefaultTabController.of(context).animateTo(0);
            },
            icon: Icon(Icons.arrow_back),
            label: Text('العودة للرئيسية'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(SleepTrackingProvider provider) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: TextButton.icon(
        onPressed: () {
          // TODO: تحميل المزيد
        },
        icon: Icon(Icons.refresh),
        label: Text('تحميل المزيد'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
    );
  }
}