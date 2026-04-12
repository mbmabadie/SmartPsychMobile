// lib/shared/widgets/smart_insights_widget.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Widget للرؤى الذكية التفاعلية
class SmartInsightsWidget extends StatefulWidget {
  final String period;
  final String category;
  final bool isTablet;
  final List<Map<String, dynamic>>? customInsights;

  const SmartInsightsWidget({
    super.key,
    required this.period,
    required this.category,
    this.isTablet = false,
    this.customInsights,
  });

  @override
  State<SmartInsightsWidget> createState() => _SmartInsightsWidgetState();
}

class _SmartInsightsWidgetState extends State<SmartInsightsWidget>
    with TickerProviderStateMixin {

  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  int _currentInsightIndex = 0;
  List<Map<String, dynamic>> _insights = [];

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadInsights();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(SmartInsightsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period || oldWidget.category != widget.category) {
      _loadInsights();
      _slideController.reset();
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _loadInsights() {
    setState(() {
      _insights = widget.customInsights ?? _generateInsights();
      _currentInsightIndex = 0;
    });
  }

  void _nextInsight() {
    if (_insights.isNotEmpty) {
      setState(() {
        _currentInsightIndex = (_currentInsightIndex + 1) % _insights.length;
      });
    }
  }

  void _previousInsight() {
    if (_insights.isNotEmpty) {
      setState(() {
        _currentInsightIndex =
            (_currentInsightIndex - 1 + _insights.length) % _insights.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_insights.isEmpty) {
      return _buildEmptyState();
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        padding: EdgeInsets.all(widget.isTablet ? 24 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(widget.isTablet ? 24 : 20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: widget.isTablet ? 20 : 16),
            _buildInsightContent(),
            if (_insights.length > 1) ...[
              SizedBox(height: widget.isTablet ? 20 : 16),
              _buildNavigationDots(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            padding: EdgeInsets.all(widget.isTablet ? 12 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(widget.isTablet ? 16 : 12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.psychology_rounded,
              size: widget.isTablet ? 24 : 20,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: widget.isTablet ? 16 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الرؤى الذكية',
                style: TextStyle(
                  fontSize: widget.isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '${widget.category} - ${widget.period}',
                style: TextStyle(
                  fontSize: widget.isTablet ? 14 : 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        if (_insights.length > 1)
          Row(
            children: [
              IconButton(
                onPressed: _previousInsight,
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: widget.isTablet ? 20 : 16,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                onPressed: _nextInsight,
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: widget.isTablet ? 20 : 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildInsightContent() {
    final currentInsight = _insights[_currentInsightIndex];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_currentInsightIndex),
        padding: EdgeInsets.all(widget.isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(widget.isTablet ? 16 : 12),
          border: Border.all(
            color: currentInsight['color'].withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(widget.isTablet ? 8 : 6),
                  decoration: BoxDecoration(
                    color: currentInsight['color'].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(widget.isTablet ? 10 : 8),
                  ),
                  child: Icon(
                    currentInsight['icon'],
                    size: widget.isTablet ? 20 : 16,
                    color: currentInsight['color'],
                  ),
                ),
                SizedBox(width: widget.isTablet ? 12 : 10),
                Expanded(
                  child: Text(
                    currentInsight['title'],
                    style: TextStyle(
                      fontSize: widget.isTablet ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: currentInsight['color'],
                    ),
                  ),
                ),
                if (currentInsight['priority'] == 'high')
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isTablet ? 8 : 6,
                      vertical: widget.isTablet ? 4 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(widget.isTablet ? 8 : 6),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      'مهم',
                      style: TextStyle(
                        fontSize: widget.isTablet ? 10 : 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: widget.isTablet ? 12 : 10),
            Text(
              currentInsight['message'],
              style: TextStyle(
                fontSize: widget.isTablet ? 14 : 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
            if (currentInsight['actionable'] == true) ...[
              SizedBox(height: widget.isTablet ? 16 : 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleInsightAction(currentInsight),
                      icon: Icon(
                        Icons.lightbulb_outline_rounded,
                        size: widget.isTablet ? 18 : 16,
                      ),
                      label: Text(
                        'اتخاذ إجراء',
                        style: TextStyle(
                          fontSize: widget.isTablet ? 14 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentInsight['color'],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: widget.isTablet ? 12 : 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(widget.isTablet ? 12 : 10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_insights.length, (index) {
        final isActive = index == _currentInsightIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: widget.isTablet ? 4 : 2),
          width: isActive ? (widget.isTablet ? 24 : 20) : (widget.isTablet ? 8 : 6),
          height: widget.isTablet ? 8 : 6,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(widget.isTablet ? 4 : 3),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(widget.isTablet ? 32 : 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(widget.isTablet ? 24 : 20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: widget.isTablet ? 48 : 40,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          SizedBox(height: widget.isTablet ? 16 : 12),
          Text(
            'لا توجد رؤى متاحة',
            style: TextStyle(
              fontSize: widget.isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: widget.isTablet ? 8 : 6),
          Text(
            'سيتم إنتاج رؤى ذكية بناءً على بياناتك قريباً',
            style: TextStyle(
              fontSize: widget.isTablet ? 14 : 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleInsightAction(Map<String, dynamic> insight) {
    // تنفيذ الإجراء المناسب بناءً على نوع الرؤية
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إجراء: ${insight['title']}'),
        content: Text('سيتم تنفيذ الإجراء المناسب لهذه الرؤية'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateInsights() {
    // إنتاج رؤى ذكية بناءً على الفئة والفترة المحددة
    final baseInsights = _getBaseInsights();
    final categoryInsights = _getCategorySpecificInsights();
    final periodInsights = _getPeriodSpecificInsights();

    return [...baseInsights, ...categoryInsights, ...periodInsights];
  }

  List<Map<String, dynamic>> _getBaseInsights() {
    return [
      {
        'icon': Icons.trending_up_rounded,
        'color': Colors.green,
        'title': 'تحسن عام',
        'message': 'تُظهر بياناتك تحسناً تدريجياً في ${widget.category} خلال ${widget.period}',
        'priority': 'medium',
        'actionable': true,
      },
    ];
  }

  List<Map<String, dynamic>> _getCategorySpecificInsights() {
    switch (widget.category) {
      case 'النوم':
        return [
          {
            'icon': Icons.bedtime_rounded,
            'color': Colors.purple,
            'title': 'نمط نوم منتظم',
            'message': 'حافظت على وقت نوم ثابت في معظم الأيام، مما يحسن جودة نومك',
            'priority': 'medium',
            'actionable': false,
          },
          {
            'icon': Icons.schedule_rounded,
            'color': Colors.blue,
            'title': 'تحسين وقت النوم',
            'message': 'يمكنك تحسين نومك بالذهاب للسرير 30 دقيقة أسرع',
            'priority': 'high',
            'actionable': true,
          },
        ];
      case 'الهاتف':
        return [
          {
            'icon': Icons.phone_android_rounded,
            'color': AppColors.secondary,
            'title': 'تقليل الاستخدام',
            'message': 'قللت استخدام الهاتف بنسبة 15% مقارنة بالفترة السابقة',
            'priority': 'medium',
            'actionable': false,
          },
          {
            'icon': Icons.nightlight_round,
            'color': Colors.indigo,
            'title': 'استخدام ليلي',
            'message': 'لوحظ استخدام الهاتف في ساعات متأخرة، قد يؤثر على نومك',
            'priority': 'high',
            'actionable': true,
          },
        ];
      case 'النشاط':
        return [
          {
            'icon': Icons.directions_run_rounded,
            'color': Colors.green,
            'title': 'نشاط ممتاز',
            'message': 'حققت هدف الخطوات في معظم أيام ${widget.period}',
            'priority': 'medium',
            'actionable': false,
          },
          {
            'icon': Icons.local_fire_department_rounded,
            'color': Colors.orange,
            'title': 'حرق سعرات جيد',
            'message': 'معدل حرق السعرات الحرارية يُظهر تحسناً مستمراً',
            'priority': 'low',
            'actionable': true,
          },
        ];
      case 'التغذية':
        return [
          {
            'icon': Icons.restaurant_rounded,
            'color': Colors.orange,
            'title': 'وجبات منتظمة',
            'message': 'حافظت على 3 وجبات منتظمة في معظم الأيام',
            'priority': 'medium',
            'actionable': false,
          },
          {
            'icon': Icons.water_drop_rounded,
            'color': Colors.blue,
            'title': 'شرب الماء',
            'message': 'تحتاج لزيادة كمية الماء المستهلكة يومياً',
            'priority': 'high',
            'actionable': true,
          },
        ];
      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _getPeriodSpecificInsights() {
    switch (widget.period) {
      case 'يومي':
        return [
          {
            'icon': Icons.today_rounded,
            'color': Colors.blue,
            'title': 'يوم جيد',
            'message': 'أداؤك اليوم كان أفضل من متوسط الأسبوع',
            'priority': 'low',
            'actionable': false,
          },
        ];
      case 'أسبوعي':
        return [
          {
            'icon': Icons.calendar_view_week_rounded,
            'color': Colors.purple,
            'title': 'أسبوع متوازن',
            'message': 'هذا الأسبوع أظهر توازناً جيداً في جميع الجوانب',
            'priority': 'medium',
            'actionable': false,
          },
        ];
      case 'شهري':
        return [
          {
            'icon': Icons.calendar_month_rounded,
            'color': Colors.green,
            'title': 'تقدم شهري',
            'message': 'تحسن ملحوظ في ${widget.category} مقارنة بالشهر الماضي',
            'priority': 'medium',
            'actionable': false,
          },
        ];
      case 'سنوي':
        return [
          {
            'icon': Icons.calendar_today_rounded,
            'color': Colors.amber,
            'title': 'إنجاز سنوي',
            'message': 'حققت تطوراً كبيراً في ${widget.category} هذا العام',
            'priority': 'low',
            'actionable': false,
          },
        ];
      default:
        return [];
    }
  }
}