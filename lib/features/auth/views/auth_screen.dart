// lib/features/auth/views/auth_screen.dart

import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../shared/theme/app_colors.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const AuthScreen({Key? key, required this.onAuthSuccess}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Login
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();

  // Register
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  final _regAge = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    _regAge.dispose();
    super.dispose();
  }

  Future<void> _showServerSettingsDialog() async {
    final controller = TextEditingController(text: ApiService.instance.baseUrl);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.dns_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('عنوان السيرفر'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'http://192.168.1.100:3000/api',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.info),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'استخدم IP السيرفر إذا كنت على شبكة محلية',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                await ApiService.instance.setBaseUrl(url);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم حفظ العنوان: $url'), backgroundColor: AppColors.success),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _errorMessage = null; });

    final result = await ApiService.instance.login(_loginEmail.text.trim(), _loginPassword.text);

    if (result['success'] == true) {
      // بدء المزامنة بعد الدخول
      SyncService.instance.startAutoSync();
      SyncService.instance.syncAll();
      widget.onAuthSuccess();
    } else {
      setState(() { _errorMessage = result['message'] ?? 'فشل تسجيل الدخول'; });
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _errorMessage = null; });

    final result = await ApiService.instance.register(
      _regEmail.text.trim(),
      _regPassword.text,
      _regName.text.trim(),
    );

    if (result['success'] == true) {
      SyncService.instance.startAutoSync();
      SyncService.instance.syncAll();
      widget.onAuthSuccess();
    } else {
      setState(() { _errorMessage = result['message'] ?? 'فشل إنشاء الحساب'; });
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            // زر إعدادات السيرفر في الأعلى
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                icon: Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                onPressed: _showServerSettingsDialog,
                tooltip: 'إعدادات السيرفر',
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology_outlined, size: 64, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Smart Psych', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text('تتبع صحتك النفسية والجسدية', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 32),

                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'تسجيل الدخول'),
                        Tab(text: 'حساب جديد'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                        ],
                      ),
                    ),

                  // Forms
                  SizedBox(
                    height: 320,
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildLoginForm(), _buildRegisterForm()],
                    ),
                  ),

                  // Skip
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: widget.onAuthSuccess,
                    child: Text('تخطي - استخدام بدون حساب', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _loginEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('البريد الإلكتروني', Icons.email_outlined),
            validator: (v) => v == null || !v.contains('@') ? 'بريد إلكتروني غير صحيح' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _loginPassword,
            obscureText: _obscurePassword,
            decoration: _inputDecoration('كلمة المرور', Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => v == null || v.length < 6 ? 'كلمة المرور قصيرة (6 أحرف على الأقل)' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('دخول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _regName,
            decoration: _inputDecoration('الاسم الكامل', Icons.person_outline),
            validator: (v) => v == null || v.isEmpty ? 'الاسم مطلوب' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('البريد الإلكتروني', Icons.email_outlined),
            validator: (v) => v == null || !v.contains('@') ? 'بريد إلكتروني غير صحيح' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regPassword,
            obscureText: true,
            decoration: _inputDecoration('كلمة المرور', Icons.lock_outline),
            validator: (v) => v == null || v.length < 6 ? '6 أحرف على الأقل' : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('إنشاء حساب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
