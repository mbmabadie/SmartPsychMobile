// lib/screens/dialogs/goal_creation_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/models/activity_models.dart';
import '../../../../core/database/models/goal_type.dart';
import '../../../../shared/theme/app_colors.dart';

class GoalCreationDialog extends StatefulWidget {
  const GoalCreationDialog({Key? key}) : super(key: key);

  @override
  State<GoalCreationDialog> createState() => _GoalCreationDialogState();
}

class _GoalCreationDialogState extends State<GoalCreationDialog> {
  late PageController _pageController;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();

  int _currentStep = 0;
  bool _isCreating = false;

  GoalType? _selectedGoalType;
  ActivityType _selectedActivityType = ActivityType.walking;
  String _selectedDuration = 'يومي';
  DateTime? _endDate;

  final List<GoalTypeOption> _goalTypes = [
    GoalTypeOption(
      type: GoalType.steps,
      icon: Icons.directions_walk,
      title: 'الخطوات',
      description: 'عدد الخطوات المستهدفة',
      unit: 'خطوة',
      color: AppColors.walking,
      defaultTarget: 10000,
      examples: ['5,000 خطوة', '10,000 خطوة', '15,000 خطوة'],
    ),
    GoalTypeOption(
      type: GoalType.distance,
      icon: Icons.straighten,
      title: 'المسافة',
      description: 'المسافة المستهدفة للمشي أو الجري',
      unit: 'كيلومتر',
      color: AppColors.cycling,
      defaultTarget: 5,
      examples: ['3 كم', '5 كم', '10 كم'],
    ),
    GoalTypeOption(
      type: GoalType.duration,
      icon: Icons.access_time,
      title: 'مدة النشاط',
      description: 'الوقت المستهدف للنشاط البدني',
      unit: 'دقيقة',
      color: AppColors.energy,
      defaultTarget: 30,
      examples: ['20 دقيقة', '30 دقيقة', '60 دقيقة'],
    ),
    GoalTypeOption(
      type: GoalType.calories,
      icon: Icons.local_fire_department,
      title: 'السعرات المحروقة',
      description: 'السعرات الحرارية المستهدف حرقها',
      unit: 'سعرة حرارية',
      color: AppColors.running,
      defaultTarget: 500,
      examples: ['300 سعرة', '500 سعرة', '800 سعرة'],
    ),
  ];

  final List<String> _durations = ['يومي', 'أسبوعي', 'شهري'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: _buildDialogContent(),
    );
  }

  Widget _buildDialogContent() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 650),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildProgressIndicator(),
          Flexible(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildGoalTypeStep(),
                _buildGoalDetailsStep(),
                _buildGoalSummaryStep(),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.flag,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إنشاء هدف جديد',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'حدد هدفاً جديداً لتحفيز نفسك',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: AppColors.textSecondary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceLight,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.accent : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 2) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGoalTypeStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ما نوع الهدف الذي تريد تحقيقه؟',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر نوع الهدف المناسب لك',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _goalTypes.length,
              itemBuilder: (context, index) {
                final goalType = _goalTypes[index];
                final isSelected = _selectedGoalType == goalType.type;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectGoalType(goalType.type),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? goalType.color.withOpacity(0.1)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? goalType.color
                                : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: goalType.color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                goalType.icon,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        goalType.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? goalType.color
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: goalType.color,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    goalType.description,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: goalType.examples.map((example) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: goalType.color,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          example,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalDetailsStep() {
    final selectedGoalTypeOption = _goalTypes.firstWhere(
          (g) => g.type == _selectedGoalType,
      orElse: () => _goalTypes.first,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                selectedGoalTypeOption.icon,
                color: selectedGoalTypeOption.color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'تفاصيل هدف ${selectedGoalTypeOption.title}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildInputField(
            controller: _titleController,
            label: 'اسم الهدف',
            hint: 'مثال: ${selectedGoalTypeOption.title} ${_selectedDuration.toLowerCase()}',
            icon: Icons.edit,
          ),

          const SizedBox(height: 16),

          _buildInputField(
            controller: _targetController,
            label: 'الهدف المطلوب',
            hint: '${selectedGoalTypeOption.defaultTarget} ${selectedGoalTypeOption.unit}',
            icon: Icons.track_changes,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            suffix: Text(
              selectedGoalTypeOption.unit,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'مدة الهدف',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildDurationSelector(),

          const SizedBox(height: 24),

          if (_selectedGoalType == GoalType.distance || _selectedGoalType == GoalType.duration)
            _buildActivityTypeSelector(),

          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: selectedGoalTypeOption.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'نصيحة لتحقيق الهدف',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getMotivationalTip(selectedGoalTypeOption.type),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSummaryStep() {
    final selectedGoalTypeOption = _goalTypes.firstWhere(
          (g) => g.type == _selectedGoalType,
      orElse: () => _goalTypes.first,
    );

    final target = _targetController.text.isNotEmpty
        ? _targetController.text
        : selectedGoalTypeOption.defaultTarget.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص الهدف',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selectedGoalTypeOption.color,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selectedGoalTypeOption.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        selectedGoalTypeOption.icon,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleController.text.isNotEmpty
                                ? _titleController.text
                                : '${selectedGoalTypeOption.title} $_selectedDuration',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedGoalTypeOption.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryDetail(
                        'الهدف',
                        '$target ${selectedGoalTypeOption.unit}',
                        Icons.track_changes,
                        selectedGoalTypeOption.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryDetail(
                        'المدة',
                        _selectedDuration,
                        Icons.schedule,
                        selectedGoalTypeOption.color,
                      ),
                    ),
                  ],
                ),

                if (_selectedGoalType == GoalType.distance || _selectedGoalType == GoalType.duration) ...[
                  const SizedBox(height: 12),
                  _buildSummaryDetail(
                    'نوع النشاط',
                    _getActivityTypeName(_selectedActivityType),
                    Icons.directions_run,
                    selectedGoalTypeOption.color,
                    fullWidth: true,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'أنت على وشك البدء!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'هدفك الجديد سيساعدك على تحسين صحتك وحفز نشاطك اليومي',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDetail(
      String label,
      String value,
      IconData icon,
      Color color,
      {bool fullWidth = false}
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: fullWidth
          ? Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      )
          : Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.textSecondary,
              size: 20,
            ),
            suffixIcon: suffix != null ? Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                widthFactor: 1.0,
                child: suffix,
              ),
            ) : null,
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.accent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Row(
      children: _durations.map((duration) {
        final isSelected = _selectedDuration == duration;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: _durations.indexOf(duration) < _durations.length - 1 ? 8 : 0,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _selectedDuration = duration),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    duration,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityTypeSelector() {
    final activityTypes = [
      {'type': ActivityType.walking, 'name': 'المشي', 'icon': Icons.directions_walk},
      {'type': ActivityType.running, 'name': 'الجري', 'icon': Icons.directions_run},
      {'type': ActivityType.cycling, 'name': 'ركوب الدراجة', 'icon': Icons.directions_bike},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نوع النشاط',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: activityTypes.map((activity) {
            final isSelected = _selectedActivityType == activity['type'];
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: activityTypes.indexOf(activity) < activityTypes.length - 1 ? 8 : 0,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _selectedActivityType = activity['type'] as ActivityType),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            activity['icon'] as IconData,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity['name'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: TextButton(
                onPressed: _previousStep,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'السابق',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _canProceed() && !_isCreating ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isCreating
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_currentStep < 2)
                    const Text(
                      'التالي',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Text(
                      'إنشاء الهدف',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _currentStep < 2 ? Icons.arrow_forward : Icons.flag,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectGoalType(GoalType goalType) {
    setState(() {
      _selectedGoalType = goalType;
      final goalTypeOption = _goalTypes.firstWhere((g) => g.type == goalType);
      _titleController.text = '${goalTypeOption.title} $_selectedDuration';
      _targetController.text = goalTypeOption.defaultTarget.toString();
    });
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedGoalType != null;
      case 1:
        return _titleController.text.isNotEmpty &&
            _targetController.text.isNotEmpty;
      case 2:
        return true;
      default:
        return false;
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _createGoal();
    }
  }

  Future<void> _createGoal() async {
    setState(() {
      _isCreating = true;
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      final goalData = {
        'title': _titleController.text,
        'activityType': _selectedActivityType,
        'goalType': _selectedGoalType!,
        'targetValue': double.parse(_targetController.text),
        'endDate': _endDate,
      };

      Navigator.of(context).pop(goalData);
    }
  }

  String _getMotivationalTip(GoalType goalType) {
    switch (goalType) {
      case GoalType.steps:
        return 'ابدأ بهدف صغير وزده تدريجياً. كل خطوة تقربك من هدفك!';
      case GoalType.distance:
        return 'المسافات الطويلة تُقطع بخطوات صغيرة. كن صبوراً ومستمراً.';
      case GoalType.duration:
        return 'حتى 10 دقائق من النشاط يومياً تصنع فرقاً كبيراً في صحتك.';
      case GoalType.calories:
        return 'حرق السعرات يحسن مزاجك ويزيد طاقتك. استمتع بالرحلة!';
      default:
        return 'استمر في العمل نحو هدفك!';
    }
  }

  String _getActivityTypeName(ActivityType activityType) {
    switch (activityType) {
      case ActivityType.walking:
        return 'المشي';
      case ActivityType.running:
        return 'الجري';
      case ActivityType.cycling:
        return 'ركوب الدراجة';
      default:
        return 'نشاط عام';
    }
  }
}

class GoalTypeOption {
  final GoalType type;
  final IconData icon;
  final String title;
  final String description;
  final String unit;
  final Color color;
  final double defaultTarget;
  final List<String> examples;

  const GoalTypeOption({
    required this.type,
    required this.icon,
    required this.title,
    required this.description,
    required this.unit,
    required this.color,
    required this.defaultTarget,
    required this.examples,
  });
}