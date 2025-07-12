// screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../backend/profile_logic.dart';
import '../models/profile_model.dart';
import '../backend/auth_service.dart';
import '../widgets/app_sidebar.dart';
import 'animated_page_transition.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for editing
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController = TextEditingController();
  
  ProfileModel? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isArabic = false;
  
  // Color scheme
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFF64B5F6);
  static const Color darkBlue = Color(0xFF1976D2);
  static const Color backgroundColor = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _profileService.getCurrentUserProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
        // Fill controllers with current data
        if (profile != null) {
          _fullNameController.text = profile.fullName;
          _phoneController.text = profile.phone;
          _roleController.text = profile.role;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isArabic ? 'خطأ في تحميل بيانات الملف الشخصي' : 'Error loading profile data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updatedProfile = await _profileService.updateUserProfile(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _roleController.text.trim(),
      );
      
      setState(() {
        _profile = updatedProfile;
        _isEditing = false;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isArabic ? 'تم تحديث البيانات بنجاح' : 'Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isArabic ? 'فشل في تحديث البيانات' : 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleLanguage() {
    setState(() {
      _isArabic = !_isArabic;
    });
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing && _profile != null) {
        // Reset controllers to original values if cancelled
        _fullNameController.text = _profile!.fullName;
        _phoneController.text = _profile!.phone;
        _roleController.text = _profile!.role;
      }
    });
  }

  void _changePassword() async {
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    final _passwordFormKey = GlobalKey<FormState>();
    bool _isPasswordLoading = false;
    bool _obscureNewPassword = true;
    bool _obscureConfirmPassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            _isArabic ? 'تغيير كلمة المرور' : 'Change Password',
            style: const TextStyle(color: darkBlue),
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: _passwordFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isArabic 
                                ? 'سيتم تغيير كلمة المرور مباشرة. تأكد من حفظ كلمة المرور الجديدة.'
                                : 'Your password will be changed immediately. Make sure to save your new password.',
                            style: TextStyle(color: Colors.blue[700], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // New Password Field
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: _isArabic ? 'كلمة المرور الجديدة' : 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setDialogState(() => _obscureNewPassword = !_obscureNewPassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _isArabic ? 'كلمة المرور الجديدة مطلوبة' : 'New password is required';
                      }
                      if (!_authService.isValidPassword(value)) {
                        return _isArabic 
                            ? 'كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل مع أرقام وحروف كبيرة وصغيرة'
                            : 'Password must be at least 8 characters with numbers, uppercase and lowercase letters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: _isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setDialogState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _isArabic ? 'تأكيد كلمة المرور مطلوب' : 'Password confirmation is required';
                      }
                      if (value != _newPasswordController.text) {
                        return _isArabic ? 'كلمة المرور غير متطابقة' : 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isPasswordLoading ? null : () => Navigator.pop(context),
              child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: _isPasswordLoading ? null : () async {
                if (_passwordFormKey.currentState!.validate()) {
                  setDialogState(() => _isPasswordLoading = true);
                  
                  try {
                    // Note: In Supabase, we cannot verify the current password directly
                    // The user needs to re-authenticate if this is a sensitive operation
                    // For now, we'll trust the user and proceed with password change
                    
                    // Change password
                    await _authService.changePassword(newPassword: _newPasswordController.text);
                    
                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isArabic ? 'تم تغيير كلمة المرور بنجاح' : 'Password changed successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => _isPasswordLoading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isArabic ? 'فشل في تغيير كلمة المرور: ${e.toString()}' : 'Failed to change password: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
              child: _isPasswordLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(_isArabic ? 'تغيير' : 'Change'),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isArabic ? 'تسجيل الخروج' : 'Logout'),
        content: Text(_isArabic ? 'هل أنت متأكد من تسجيل الخروج؟' : 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.logout();
              if (mounted) {
                navigateWithAnimation(context, const LoginScreen());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(_isArabic ? 'تسجيل الخروج' : 'Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Row(
          children: [
            // Side Navigation
            AppSidebar(
              parentContext: context,
              selectedPage: 'profile',
              isArabic: _isArabic,
            ),
            
            // Main Content
            Expanded(
              child: Column(
                children: [
                  // Top Bar
                  Container(
                    height: 80,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        // Page Title
                        Text(
                          _isArabic ? 'الملف الشخصي' : 'Profile',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: darkBlue,
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Language Toggle
                        InkWell(
                          onTap: _toggleLanguage,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: lightBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: lightBlue),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isArabic ? '🇸🇦 العربية' : '🇬🇧 English',
                                  style: const TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.language,
                                  color: primaryBlue,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content Area
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: primaryBlue,
                            ),
                          )
                        : _profile == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _isArabic ? 'لم يتم العثور على بيانات المستخدم' : 'No profile data found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadProfile,
                                      child: Text(_isArabic ? 'إعادة المحاولة' : 'Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 600),
                                    child: Column(
                                      children: [
                                        _buildProfileHeader(),
                                        const SizedBox(height: 32),
                                        _buildProfileForm(),
                                        const SizedBox(height: 32),
                                        _buildActionButtons(),
                                      ],
                                    ),
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
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Avatar
          CircleAvatar(
            backgroundColor: primaryBlue.withOpacity(0.1),
            radius: 50,
            child: Text(
              _profile!.fullName.isNotEmpty 
                  ? _profile!.fullName.substring(0, 1).toUpperCase()
                  : '?',
              style: const TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Name and Role
          Text(
            _profile!.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: lightBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getRoleDisplayName(_profile!.role),
              style: const TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Title
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  _isArabic ? 'المعلومات الشخصية' : 'Personal Information',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Full Name Field
            _buildFormField(
              controller: _fullNameController,
              label: _isArabic ? 'الاسم الكامل' : 'Full Name',
              icon: Icons.person,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return _isArabic ? 'الاسم الكامل مطلوب' : 'Full name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Phone Field
            _buildFormField(
              controller: _phoneController,
              label: _isArabic ? 'رقم الهاتف' : 'Phone Number',
              icon: Icons.phone,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return _isArabic ? 'رقم الهاتف مطلوب' : 'Phone number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Role Field
            _buildFormField(
              controller: _roleController,
              label: _isArabic ? 'المنصب' : 'Role',
              icon: Icons.work_outline,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return _isArabic ? 'المنصب مطلوب' : 'Role is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Email (Read Only)
            _buildInfoRow(
              _isArabic ? 'البريد الإلكتروني' : 'Email',
              _authService.currentUserEmail ?? '',
              Icons.email,
            ),
            const SizedBox(height: 16),
            
            // Created Date
            _buildInfoRow(
              _isArabic ? 'تاريخ الإنشاء' : 'Created',
              _formatDate(_profile!.createdAt),
              Icons.calendar_today,
            ),
            const SizedBox(height: 16),
            
            // Last Updated
            _buildInfoRow(
              _isArabic ? 'آخر تحديث' : 'Last Updated',
              _formatDate(_profile!.updatedAt),
              Icons.update,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: enabled ? Colors.black87 : Colors.grey[600],
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: enabled ? primaryBlue : Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[50],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isEditing) ...[
            // Save and Cancel buttons when editing
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updateProfile,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isArabic ? 'حفظ' : 'Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _toggleEditing,
                    icon: const Icon(Icons.cancel),
                    label: Text(_isArabic ? 'إلغاء' : 'Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Edit and Logout buttons when not editing
            ElevatedButton.icon(
              onPressed: _toggleEditing,
              icon: const Icon(Icons.edit),
              label: Text(_isArabic ? 'تعديل البيانات' : 'Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _changePassword,
              icon: const Icon(Icons.lock_reset),
              label: Text(_isArabic ? 'تغيير كلمة المرور' : 'Change Password'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: const BorderSide(color: primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: Text(_isArabic ? 'تسجيل الخروج' : 'Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    if (_isArabic) {
      switch (role.toLowerCase()) {
        case 'doctor':
          return 'طبيب';
        case 'nurse':
          return 'ممرض/ممرضة';
        case 'admin':
          return 'إداري';
        case 'receptionist':
          return 'موظف استقبال';
        default:
          return role;
      }
    }
    return role.toUpperCase();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
