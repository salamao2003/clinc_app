// screens/login_screen.dart
import 'package:flutter/material.dart';
import '../backend/auth_service.dart';
import 'signup_screen.dart';
import 'package:clinc_app/screens/animated_page_transition.dart';
import 'patients_screen.dart'; // استيراد شاشة المرضى

const Color primaryBlue = Color(0xFF2196F3);
const Color lightBlue = Color(0xFF64B5F6);
const Color darkBlue = Color(0xFF1976D2);
const Color backgroundColor = Color(0xFFFAFAFA);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isArabic = false; // Language state

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isArabic ? 'تم تسجيل الدخول بنجاح' : 'Login successful'),
              backgroundColor: Colors.green,
            ),
          );
          // انتقل لصفحة المرضى مع الأنيميشن
          navigateWithAnimation(context, const PatientsScreen());
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isArabic ? 'خطأ في البريد الإلكتروني أو كلمة المرور' : 'Invalid email or password'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isArabic ? 'حدث خطأ أثناء تسجيل الدخول' : 'Login failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleLanguage() {
    setState(() {
      _isArabic = !_isArabic;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Row(
          children: [
            // Left side - Logo/Branding area (40% of screen)
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryBlue.withOpacity(0.1),
                      lightBlue.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Large logo
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          size: 100,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Welcome text
                      Text(
                        _isArabic ? 'مرحباً بك في' : 'Welcome to',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isArabic ? 'نظام إدارة العيادة' : 'Insta Clinic',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isArabic
                            ? 'إدارة شاملة وفعالة للعيادات الطبية'
                            : 'Comprehensive and efficient clinic management',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Right side - Login form (60% of screen)
            Expanded(
              flex: 6,
              child: Container(
                color: Colors.white,
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 40.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Language switcher
                          Align(
                            alignment: _isArabic ? Alignment.centerLeft : Alignment.centerRight,
                            child: InkWell(
                              onTap: _toggleLanguage,
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: lightBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: lightBlue, width: 1.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isArabic ? '🇸🇦 العربية' : '🇬🇧 English',
                                      style: const TextStyle(
                                        color: primaryBlue,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.language,
                                      color: primaryBlue,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 60),

                          // Login title
                          Text(
                            _isArabic ? 'تسجيل الدخول' : 'Sign In',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: darkBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isArabic ? 'أدخل بياناتك للوصول إلى النظام' : 'Enter your credentials to access the system',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 50),

                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    labelText: _isArabic ? 'البريد الإلكتروني' : 'Email Address',
                                    hintText: _isArabic ? 'أدخل البريد الإلكتروني' : 'Enter your email address',
                                    prefixIcon: const Icon(Icons.email_outlined, color: primaryBlue),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: primaryBlue, width: 2),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return _isArabic ? 'البريد الإلكتروني مطلوب' : 'Email is required';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return _isArabic ? 'البريد الإلكتروني غير صالح' : 'Invalid email format';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Password field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    labelText: _isArabic ? 'كلمة المرور' : 'Password',
                                    hintText: _isArabic ? 'أدخل كلمة المرور' : 'Enter your password',
                                    prefixIcon: const Icon(Icons.lock_outline, color: primaryBlue),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: primaryBlue,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: primaryBlue, width: 2),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return _isArabic ? 'كلمة المرور مطلوبة' : 'Password is required';
                                    }
                                    if (value.length < 6) {
                                      return _isArabic ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' : 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Forgot password
                                Align(
                                  alignment: _isArabic ? Alignment.centerLeft : Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      // Handle forgot password
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(_isArabic ? 'سيتم إضافة هذه الميزة قريباً' : 'Feature coming soon'),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      _isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
                                      style: const TextStyle(
                                        color: primaryBlue,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Login button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            _isArabic ? 'تسجيل الدخول' : 'Sign In',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey[400])),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        _isArabic ? 'أو' : 'or',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey[400])),
                                  ],
                                ),
                                const SizedBox(height: 30),

                                // Create account button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: () {
                                     navigateWithAnimation(context, const SignUpScreen());
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryBlue,
                                      side: const BorderSide(color: primaryBlue, width: 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _isArabic ? 'إنشاء حساب جديد' : 'Create New Account',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}