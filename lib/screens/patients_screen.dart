// screens/patients_screen.dart
import 'package:flutter/material.dart';
import '../backend_local/patient_service_local.dart';
import '../models/patient_model.dart';
import 'login_screen.dart';
import '../widgets/app_sidebar.dart';
class PatientsScreen extends StatefulWidget {
  const PatientsScreen({Key? key}) : super(key: key);

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _searchController = TextEditingController();
  
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  bool _isArabic = false;
  String _searchQuery = '';

  // Color scheme
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFF64B5F6);
  static const Color darkBlue = Color(0xFF1976D2);
  static const Color backgroundColor = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      final patients = await PatientServiceLocal.getAllPatients();
      setState(() {
        _patients = patients;
        _filteredPatients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isArabic ? 'خطأ في تحميل بيانات المرضى' : 'Error loading patients data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _searchPatients(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPatients = _patients;
      } else {
        _filteredPatients = _patients.where((patient) {
          return patient.fullName.toLowerCase().contains(query.toLowerCase()) ||
                 patient.phoneNumber.contains(query) ||
                 patient.email.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _deletePatient(Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isArabic ? 'تأكيد الحذف' : 'Confirm Delete'),
        content: Text(_isArabic 
          ? 'هل أنت متأكد من حذف المريض ${patient.fullName}؟'
          : 'Are you sure you want to delete patient ${patient.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_isArabic ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await PatientServiceLocal.deletePatient(patient.id);
      if (result['success']) {
        _fetchPatients();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isArabic ? 'تم حذف المريض بنجاح' : 'Patient deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? (_isArabic ? 'فشل في حذف المريض' : 'Failed to delete patient')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _toggleLanguage() {
    setState(() {
      _isArabic = !_isArabic;
    });
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isArabic ? 'تسجيل الخروج' : 'Logout'),
        content: Text(_isArabic ? 'هل تريد تسجيل الخروج؟' : 'Do you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_isArabic ? 'تسجيل الخروج' : 'Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

// ...existing code...
void _showPatientDetails(Patient patient) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    backgroundColor: primaryBlue.withOpacity(0.1),
                    radius: 32,
                    child: Text(
                      patient.fullName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    patient.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildDetailRow(_isArabic ? 'الجنس' : 'Gender', _isArabic
                    ? (patient.gender.toLowerCase() == 'male' ? 'ذكر' : 'أنثى')
                    : (patient.gender.toLowerCase() == 'male' ? 'Male' : 'Female')),
                _buildDetailRow(_isArabic ? 'رقم الهاتف' : 'Phone Number', patient.phoneNumber),
                _buildDetailRow(_isArabic ? 'البريد الإلكتروني' : 'Email', patient.email),
                _buildDetailRow(_isArabic ? 'تاريخ الميلاد' : 'Date of Birth',
                  "${patient.dateOfBirth.year}-${patient.dateOfBirth.month.toString().padLeft(2, '0')}-${patient.dateOfBirth.day.toString().padLeft(2, '0')}"),
                _buildDetailRow(_isArabic ? 'العنوان' : 'Address', patient.address),
                _buildDetailRow(_isArabic ? 'رقم الطوارئ' : 'Emergency Contact', patient.emergencyContact),
                _buildDetailRow(_isArabic ? 'التاريخ الطبي' : 'Medical History', patient.medicalHistory),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_isArabic ? 'إغلاق' : 'Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

  Future<void> _showAddPatientDialog() async {
    final _formKey = GlobalKey<FormState>();
    String fullName = '';
    String gender = 'male'; // تغيير القيمة الافتراضية
    String phoneNumber = '';
    String email = '';
    DateTime? dateOfBirth;
    String address = '';
    String emergencyContact = '';
    String medicalHistory = '';
    final TextEditingController _dobController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Container(
            width: 400,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Optional: Icon
                    Center(
                      child: CircleAvatar(
                        backgroundColor: primaryBlue.withOpacity(0.1),
                        radius: 28,
                        child: const Icon(Icons.person_add, color: primaryBlue, size: 32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _isArabic ? 'إضافة مريض جديد' : 'Add New Patient',
                        style: const TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: _isArabic ? 'الاسم الكامل' : 'Full Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.isEmpty ? (_isArabic ? 'مطلوب' : 'Required') : null,
                      onChanged: (v) => fullName = v,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: gender,
                      items: [
                        DropdownMenuItem(value: 'male', child: Text(_isArabic ? 'ذكر' : 'Male')),
                        DropdownMenuItem(value: 'female', child: Text(_isArabic ? 'أنثى' : 'Female')),
                      ],
                      onChanged: (v) => gender = v ?? 'male',
                      decoration: InputDecoration(
                        labelText: _isArabic ? 'الجنس' : 'Gender',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: _isArabic ? 'رقم الهاتف *' : 'Phone Number *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.isEmpty ? (_isArabic ? 'رقم الهاتف مطلوب' : 'Phone number is required') : null,
                      onChanged: (v) => phoneNumber = v,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: _isArabic ? 'البريد الإلكتروني' : 'Email',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => email = v,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: _isArabic ? 'تاريخ الميلاد' : 'Date of Birth',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                      ),
                      validator: (v) => dateOfBirth == null ? (_isArabic ? 'مطلوب' : 'Required') : null,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000, 1, 1),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          locale: _isArabic ? const Locale('ar') : const Locale('en'),
                        );
                        if (picked != null) {
                          dateOfBirth = picked;
                          _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: _isArabic ? 'العنوان' : 'Address',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => address = v,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: _isArabic ? 'رقم الطوارئ' : 'Emergency Contact',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => emergencyContact = v,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: _isArabic ? 'التاريخ الطبي' : 'Medical History',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => medicalHistory = v,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            _isArabic ? 'إلغاء' : 'Cancel',
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (dateOfBirth == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_isArabic ? 'يرجى اختيار تاريخ الميلاد' : 'Please select date of birth'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              
                              if (phoneNumber.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_isArabic ? 'رقم الهاتف مطلوب' : 'Phone number is required'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              final newPatient = Patient(
                                id: '', // سيتم تعيين ID تلقائياً
                                fullName: fullName,
                                gender: gender,
                                phoneNumber: phoneNumber,
                                email: email,
                                dateOfBirth: dateOfBirth!,
                                address: address,
                                emergencyContact: emergencyContact,
                                emergencyPhone: '', // حقل فارغ افتراضياً
                                medicalHistory: medicalHistory,
                                allergies: '', // حقل فارغ افتراضياً
                                bloodType: '', // حقل فارغ افتراضياً
                                notes: '', // حقل فارغ افتراضياً
                                isActive: true,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                                lastVisitDate: null,
                                createdBy: 'main_user',
                              );
                              try {
                                final result = await PatientServiceLocal.addPatient(newPatient);
                                if (mounted) {
                                  Navigator.pop(context);
                                  if (result['success']) {
                                    _fetchPatients();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(_isArabic ? 'تمت إضافة المريض بنجاح' : 'Patient added successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result['message'] ?? (_isArabic ? 'فشل في إضافة المريض' : 'Failed to add patient')),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_isArabic ? 'فشل في إضافة المريض: ${e.toString()}' : 'Failed to add patient: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          child: Text(
                            _isArabic ? 'إضافة' : 'Add',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

// ...existing code...
Future<void> _showEditPatientDialog(Patient patient) async {
  final _formKey = GlobalKey<FormState>();
  String fullName = patient.fullName;
  String gender = patient.gender.toLowerCase(); // تحويل إلى أحرف صغيرة للتوافق
  String phoneNumber = patient.phoneNumber;
  String email = patient.email;
  DateTime? dateOfBirth = patient.dateOfBirth;
  String address = patient.address;
  String emergencyContact = patient.emergencyContact;
  String medicalHistory = patient.medicalHistory;
  final TextEditingController _dobController = TextEditingController(
    text: "${patient.dateOfBirth.year}-${patient.dateOfBirth.month.toString().padLeft(2, '0')}-${patient.dateOfBirth.day.toString().padLeft(2, '0')}",
  );

  await showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Container(
          width: 400,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      backgroundColor: primaryBlue.withOpacity(0.1),
                      radius: 28,
                      child: const Icon(Icons.edit, color: primaryBlue, size: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _isArabic ? 'تعديل بيانات المريض' : 'Edit Patient',
                      style: const TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    initialValue: fullName,
                    decoration: InputDecoration(
                      labelText: _isArabic ? 'الاسم الكامل' : 'Full Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? (_isArabic ? 'مطلوب' : 'Required') : null,
                    onChanged: (v) => fullName = v,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: gender,
                    items: [
                      DropdownMenuItem(value: 'male', child: Text(_isArabic ? 'ذكر' : 'Male')),
                      DropdownMenuItem(value: 'female', child: Text(_isArabic ? 'أنثى' : 'Female')),
                    ],
                    onChanged: (v) => gender = v ?? 'male',
                    decoration: InputDecoration(
                      labelText: _isArabic ? 'الجنس' : 'Gender',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: phoneNumber,
                    decoration: InputDecoration(
                      labelText: _isArabic ? 'رقم الهاتف *' : 'Phone Number *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? (_isArabic ? 'رقم الهاتف مطلوب' : 'Phone number is required') : null,
                    onChanged: (v) => phoneNumber = v,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: email,
                    decoration: InputDecoration(
                      labelText: _isArabic ? 'البريد الإلكتروني' : 'Email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => email = v,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: _isArabic ? 'تاريخ الميلاد' : 'Date of Birth',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                    ),
                    validator: (v) => dateOfBirth == null ? (_isArabic ? 'مطلوب' : 'Required') : null,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dateOfBirth ?? DateTime(2000, 1, 1),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        locale: _isArabic ? const Locale('ar') : const Locale('en'),
                      );
                      if (picked != null) {
                        dateOfBirth = picked;
                        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: address,
                    decoration: InputDecoration(
                      labelText: _isArabic ? 'العنوان' : 'Address',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => address = v,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: emergencyContact,
                    decoration: InputDecoration(
                      labelText: _isArabic ? 'رقم الطوارئ' : 'Emergency Contact',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => emergencyContact = v,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: medicalHistory,
                    decoration: InputDecoration(
                      labelText: _isArabic ? 'التاريخ الطبي' : 'Medical History',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => medicalHistory = v,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          _isArabic ? 'إلغاء' : 'Cancel',
                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate() && dateOfBirth != null) {
                            final updatedPatient = Patient(
                              id: patient.id,
                              fullName: fullName,
                              gender: gender,
                              phoneNumber: phoneNumber,
                              email: email,
                              dateOfBirth: dateOfBirth!,
                              address: address,
                              emergencyContact: emergencyContact,
                              medicalHistory: medicalHistory,
                              isActive: patient.isActive,
                              createdAt: patient.createdAt,
                              updatedAt: DateTime.now(),
                              lastVisitDate: patient.lastVisitDate,
                            );
                            try {
                              final result = await PatientServiceLocal.updatePatient(updatedPatient);
                              if (mounted) {
                                Navigator.pop(context);
                                if (result['success']) {
                                  _fetchPatients();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_isArabic ? 'تم تحديث بيانات المريض' : 'Patient updated successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['message'] ?? (_isArabic ? 'فشل في تحديث بيانات المريض' : 'Failed to update patient')),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_isArabic ? 'فشل في تحديث بيانات المريض: ${e.toString()}' : 'Failed to update patient: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Text(
                          _isArabic ? 'حفظ' : 'Save',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
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
                        selectedPage: 'patients',
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
                          _isArabic ? 'إدارة المرضى' : 'Patients Management',
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
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Search Bar and Add Button
                          Row(
                            children: [
                              // Search Bar
                              Expanded(
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _searchPatients,
                                    decoration: InputDecoration(
                                      hintText: _isArabic ? 'البحث عن مريض...' : 'Search patients...',
                                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Add New Patient Button
                              ElevatedButton.icon(
                                onPressed: _showAddPatientDialog,
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: Text(
                                  _isArabic ? 'إضافة مريض جديد' : 'Add New Patient',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Patients Table
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                                      ),
                                    )
                                  : _filteredPatients.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.people_outline,
                                                size: 64,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                _searchQuery.isEmpty
                                                    ? (_isArabic ? 'لا توجد بيانات مرضى' : 'No patients found')
                                                    : (_isArabic ? 'لا توجد نتائج للبحث' : 'No search results'),
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : SingleChildScrollView(
                                          child: DataTable(
                                            headingRowColor: MaterialStateProperty.all(
                                              primaryBlue.withOpacity(0.1),
                                            ),
                                            headingTextStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: darkBlue,
                                            ),
                                            dataRowHeight: 64,
                                            columns: [
                                              DataColumn(
                                                label: Text(_isArabic ? 'الاسم الكامل' : 'Full Name'),
                                              ),
                                              DataColumn(
                                                label: Text(_isArabic ? 'الجنس' : 'Gender'),
                                              ),
                                              DataColumn(
                                                label: Text(_isArabic ? 'رقم الهاتف' : 'Phone Number'),
                                              ),
                                              DataColumn(
                                                label: Text(_isArabic ? 'العمليات' : 'Actions'),
                                              ),
                                            ],
                                            rows: _filteredPatients.map((patient) {
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Row(
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 20,
                                                          backgroundColor: primaryBlue.withOpacity(0.1),
                                                          child: Text(
                                                            patient.fullName.substring(0, 1).toUpperCase(),
                                                            style: const TextStyle(
                                                              color: primaryBlue,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                patient.fullName,
                                                                style: const TextStyle(
                                                                  fontWeight: FontWeight.w600,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                              Text(
                                                                patient.email,
                                                                style: TextStyle(
                                                                  color: Colors.grey[600],
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: patient.gender == 'Male' 
                                                            ? Colors.blue.withOpacity(0.1)
                                                            : Colors.pink.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        _isArabic 
                                                            ? (patient.gender == 'Male' ? 'ذكر' : 'أنثى')
                                                            : patient.gender,
                                                        style: TextStyle(
                                                          color: patient.gender == 'Male' 
                                                              ? Colors.blue[700]
                                                              : Colors.pink[700],
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(Text(patient.phoneNumber)),
                                                  
                                                  DataCell(
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        // View Button
                                                        IconButton(
                                                          icon: const Icon(Icons.visibility, size: 20),
                                                          color: primaryBlue,
                                                          onPressed: () => _showPatientDetails(patient),
                                                          tooltip: _isArabic ? 'عرض' : 'View',
                                                          
                                                        ),                                                  
                                                        // Edit Button
                                                        IconButton(
                                                          icon: const Icon(Icons.edit, size: 20),
                                                          color: Colors.orange[700],
                                                          onPressed: () => _showEditPatientDialog(patient),
                                                          tooltip: _isArabic ? 'تعديل' : 'Edit',
                                                        ),
                                                        
                                                        // Delete Button
                                                        IconButton(
                                                          icon: const Icon(Icons.delete, size: 20),
                                                          color: Colors.red[700],
                                                          onPressed: () => _deletePatient(patient),
                                                          tooltip: _isArabic ? 'حذف' : 'Delete',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                            ),
                          ),                         
                          // Footer with patient count
                          if (!_isLoading && _filteredPatients.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isArabic
                                        ? 'إجمالي المرضى: ${_filteredPatients.length}'
                                        : 'Total Patients: ${_filteredPatients.length}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
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

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    final isLogout = icon == Icons.logout;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isArabic ? 'سيتم إضافة هذه الميزة قريباً' : 'Feature coming soon'),
                ),
              );
            },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: primaryBlue.withOpacity(0.3)) : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isLogout
                    ? Colors.red
                    : (isSelected ? primaryBlue : Colors.grey[600]),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isLogout
                      ? Colors.red
                      : (isSelected ? primaryBlue : Colors.grey[700]),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return _isArabic ? 'اليوم' : 'Today';
    } else if (difference.inDays == 1) {
      return _isArabic ? 'أمس' : 'Yesterday';
    } else if (difference.inDays < 7) {
      return _isArabic ? 'منذ ${difference.inDays} أيام' : '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return _isArabic ? 'منذ $weeks أسابيع' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return _isArabic ? 'منذ $months أشهر' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return _isArabic ? 'منذ $years سنوات' : '$years years ago';
    }
  }
}