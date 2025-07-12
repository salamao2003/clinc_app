import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../backend/settings_logic.dart';
import '../models/clinic_settings.dart';
import '../providers/language_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clinicNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  ClinicSettings? _currentSettings;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  bool _isChangingPassword = false;
  File? _selectedImageFile;
  String? _currentLogoUrl;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _clinicNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // تحميل الإعدادات الحالية
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await SettingsService.getClinicSettings();
      if (settings != null) {
        _currentSettings = settings;
        _clinicNameController.text = settings.clinicName;
        _addressController.text = settings.clinicAddress;
        _phoneController.text = settings.clinicPhone;
        _emailController.text = settings.clinicEmail;
        _websiteController.text = settings.clinicWebsite;
        _currentLogoUrl = settings.clinicLogoUrl;
      }
    } catch (e) {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final isArabic = languageProvider.isArabic;
      _showErrorMessage(isArabic ? 'خطأ في تحميل الإعدادات: $e' : 'Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // حفظ الإعدادات
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.isArabic;

    setState(() => _isSaving = true);

    try {
      final settings = ClinicSettings(
        id: _currentSettings?.id ?? '',
        userId: _currentSettings?.userId ?? '',
        clinicName: _clinicNameController.text.trim(),
        clinicAddress: _addressController.text.trim(),
        clinicPhone: _phoneController.text.trim(),
        clinicEmail: _emailController.text.trim(),
        clinicWebsite: _websiteController.text.trim(),
        clinicLogoUrl: _currentLogoUrl ?? '',
        createdAt: _currentSettings?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await SettingsService.saveClinicSettings(settings);
      
      if (success) {
        _showSuccessMessage(isArabic ? 'تم حفظ الإعدادات بنجاح' : 'Settings saved successfully');
        await _loadSettings(); // إعادة تحميل البيانات
      } else {
        _showErrorMessage(isArabic ? 'فشل في حفظ الإعدادات' : 'Failed to save settings');
      }
    } catch (e) {
      _showErrorMessage(isArabic ? 'خطأ في حفظ الإعدادات: $e' : 'Error saving settings: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // رفع الشعار
  Future<void> _uploadLogo() async {
    if (_selectedImageFile == null) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.isArabic;

    setState(() => _isUploadingLogo = true);

    try {
      // حذف الشعار القديم إذا وجد
      if (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty) {
        await SettingsService.deleteClinicLogo(_currentLogoUrl!);
      }

      // رفع الشعار الجديد
      final logoUrl = await SettingsService.uploadClinicLogo(_selectedImageFile!);
      
      if (logoUrl != null) {
        setState(() {
          _currentLogoUrl = logoUrl;
        });
        _showSuccessMessage(isArabic ? 'تم رفع الشعار بنجاح' : 'Logo uploaded successfully');
      } else {
        _showErrorMessage(isArabic ? 'فشل في رفع الشعار' : 'Failed to upload logo');
      }
    } catch (e) {
      _showErrorMessage(isArabic ? 'خطأ في رفع الشعار: $e' : 'Error uploading logo: $e');
    } finally {
      setState(() => _isUploadingLogo = false);
    }
  }

  // حذف الشعار
  Future<void> _deleteLogo() async {
    if (_currentLogoUrl == null || _currentLogoUrl!.isEmpty) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.isArabic;

    try {
      final success = await SettingsService.deleteClinicLogo(_currentLogoUrl!);
      if (success) {
        setState(() {
          _currentLogoUrl = '';
          _selectedImageFile = null;
        });
        _showSuccessMessage(isArabic ? 'تم حذف الشعار بنجاح' : 'Logo deleted successfully');
      } else {
        _showErrorMessage(isArabic ? 'فشل في حذف الشعار' : 'Failed to delete logo');
      }
    } catch (e) {
      _showErrorMessage(isArabic ? 'خطأ في حذف الشعار: $e' : 'Error deleting logo: $e');
    }
  }

  // اختيار صورة الشعار
  Future<void> _pickImage() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.isArabic;
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 600,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
        await _uploadLogo();
      }
    } catch (e) {
      _showErrorMessage(isArabic ? 'خطأ في اختيار الصورة: $e' : 'Error selecting image: $e');
    }
  }

  // تغيير كلمة المرور
  Future<void> _changePassword() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.isArabic;
    
    if (_currentPasswordController.text.isEmpty || 
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorMessage(isArabic ? 'يرجى ملء جميع حقول كلمة المرور' : 'Please fill all password fields');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorMessage(isArabic ? 'كلمة المرور الجديدة غير متطابقة' : 'New passwords do not match');
      return;
    }

    if (!SettingsService.isPasswordValid(_newPasswordController.text)) {
      _showErrorMessage(isArabic 
          ? 'كلمة المرور يجب أن تكون 8 أحرف على الأقل وتحتوي على حروف وأرقام' 
          : 'Password must be at least 8 characters and contain letters and numbers');
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final success = await SettingsService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (success) {
        _showSuccessMessage(isArabic ? 'تم تغيير كلمة المرور بنجاح' : 'Password changed successfully');
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        _showErrorMessage(isArabic ? 'كلمة المرور الحالية غير صحيحة' : 'Current password is incorrect');
      }
    } catch (e) {
      _showErrorMessage(isArabic ? 'خطأ في تغيير كلمة المرور: $e' : 'Error changing password: $e');
    } finally {
      setState(() => _isChangingPassword = false);
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isArabic = languageProvider.isArabic;
    
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إعدادات العيادة' : 'Clinic Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // زر تغيير اللغة
          IconButton(
            onPressed: () {
              languageProvider.toggleLanguage();
            },
            icon: const Icon(Icons.language),
            tooltip: isArabic ? 'English' : 'العربية',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClinicInfoSection(),
              const SizedBox(height: 24),
              _buildLogoSection(),
              const SizedBox(height: 24),
              _buildPasswordSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClinicInfoSection() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.isArabic;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'معلومات العيادة' : 'Clinic Information',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clinicNameController,
              decoration: InputDecoration(
                labelText: isArabic ? 'اسم العيادة *' : 'Clinic Name *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return isArabic ? 'اسم العيادة مطلوب' : 'Clinic name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: isArabic ? 'عنوان العيادة' : 'Clinic Address',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: isArabic ? 'رقم التليفون' : 'Phone Number',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[0-9+\-\s\(\)]{10,15}$').hasMatch(value)) {
                    return isArabic ? 'رقم التليفون غير صحيح' : 'Invalid phone number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: isArabic ? 'البريد الإلكتروني' : 'Email Address',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return isArabic ? 'البريد الإلكتروني غير صحيح' : 'Invalid email address';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: InputDecoration(
                labelText: isArabic ? 'الموقع الإلكتروني' : 'Website',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.language),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$').hasMatch(value)) {
                    return isArabic ? 'رابط الموقع غير صحيح' : 'Invalid website URL';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.isArabic;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'شعار العيادة' : 'Clinic Logo',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty)
              Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _currentLogoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 50);
                    },
                  ),
                ),
              )
            else
              Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isUploadingLogo ? null : _pickImage,
                  icon: _isUploadingLogo 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload),
                  label: Text(_isUploadingLogo 
                      ? (isArabic ? 'جاري الرفع...' : 'Uploading...') 
                      : (isArabic ? 'رفع شعار' : 'Upload Logo')),
                ),
                const SizedBox(width: 8),
                if (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _deleteLogo,
                    icon: const Icon(Icons.delete),
                    label: Text(isArabic ? 'حذف الشعار' : 'Delete Logo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.isArabic;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'تغيير كلمة المرور' : 'Change Password',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currentPasswordController,
              decoration: InputDecoration(
                labelText: isArabic ? 'كلمة المرور الحالية' : 'Current Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: isArabic ? 'كلمة المرور الجديدة' : 'New Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: isArabic ? 'تأكيد كلمة المرور الجديدة' : 'Confirm New Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isChangingPassword ? null : _changePassword,
              icon: _isChangingPassword 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.password),
              label: Text(_isChangingPassword 
                  ? (isArabic ? 'جاري التغيير...' : 'Changing...') 
                  : (isArabic ? 'تغيير كلمة المرور' : 'Change Password')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.isArabic;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveSettings,
        icon: _isSaving 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving 
            ? (isArabic ? 'جاري الحفظ...' : 'Saving...') 
            : (isArabic ? 'حفظ الإعدادات' : 'Save Settings')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
