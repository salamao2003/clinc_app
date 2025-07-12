import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_sidebar.dart';
import '../backend/prescription_logic.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({Key? key}) : super(key: key);

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  bool _isArabic = false;

  // ألوان ثابتة
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  // Backend logic
  final PrescriptionLogic _logic = PrescriptionLogic();
  
  // متغيرات للبيانات
  List<Prescription> _prescriptions = [];
  List<Prescription> _filteredPrescriptions = [];
  bool _loading = true;

  // متغيرات للبحث والفلاتر
  final TextEditingController _searchController = TextEditingController();
  String? _selectedDoctor;

  // متغيرات للحذف المتعدد
  Set<String> _selectedPrescriptions = {};
  bool _isMultiSelectMode = false;

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
    _searchController.addListener(() {
      _filterPrescriptions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrescriptions() async {
    setState(() => _loading = true);
    _prescriptions = await _logic.fetchPrescriptions();
    _filteredPrescriptions = _prescriptions;
    setState(() => _loading = false);
  }

  void _filterPrescriptions() {
    setState(() {
      _filteredPrescriptions = _prescriptions.where((prescription) {
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch = searchQuery.isEmpty ||
            prescription.patientName.toLowerCase().contains(searchQuery) ||
            prescription.phoneNumber.contains(searchQuery);
        
        final matchesDoctor = _selectedDoctor == null || 
            _selectedDoctor == 'الكل' ||
            _selectedDoctor == 'All' ||
            prescription.doctorName == _selectedDoctor;

        return matchesSearch && matchesDoctor;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedDoctor = null;
    });
    _filterPrescriptions();
  }

  List<String> _getUniqueDoctors() {
    final doctors = _prescriptions
        .map((p) => p.doctorName)
        .where((doctor) => doctor.isNotEmpty)
        .toSet()
        .toList();
    doctors.sort();
    return doctors;
  }

  bool _hasActiveFilters() {
    return (_selectedDoctor != null && _selectedDoctor != 'الكل' && _selectedDoctor != 'All') ||
           _searchController.text.isNotEmpty;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  // دالة طباعة الوصفة الطبية
  Future<void> _printPrescription(Prescription prescription) async {
    try {
      final pdf = pw.Document();
      
      // تحميل الخط العربي من Assets
      final arabicFontData = await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
      final arabicFont = pw.Font.ttf(arabicFontData);
      
      final arabicBoldFontData = await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf');
      final arabicFontBold = pw.Font.ttf(arabicBoldFontData);
      
      // إضافة صفحة للوصفة
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildPrescriptionPDF(prescription, arabicFont, arabicFontBold);
          },
        ),
      );

      // طباعة أو معاينة الوصفة
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '${_isArabic ? 'وصفة طبية - ' : 'Prescription - '}${prescription.patientName}',
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isArabic ? 'خطأ في طباعة الوصفة: $e' : 'Error printing prescription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // دالة بناء محتوى PDF للوصفة
  pw.Widget _buildPrescriptionPDF(Prescription prescription, pw.Font arabicFont, pw.Font arabicFontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#2196F3'),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                _isArabic ? 'وصفة طبية' : 'Medical Prescription',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  font: _isArabic ? arabicFontBold : null,
                ),
                textDirection: _isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                _isArabic ? 'عيادة طبية' : 'Medical Clinic',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.white,
                  font: _isArabic ? arabicFont : null,
                ),
                textDirection: _isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 30),
        
        // معلومات المريض والطبيب
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _isArabic ? 'معلومات المريض والطبيب' : 'Patient & Doctor Information',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: _isArabic ? arabicFontBold : null,
                ),
                textDirection: _isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
              pw.SizedBox(height: 15),
              
              // صف المريض والطبيب
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${_isArabic ? 'اسم المريض:' : 'Patient Name:'} ${prescription.patientName}',
                          style: pw.TextStyle(
                            fontSize: 14, 
                            fontWeight: pw.FontWeight.bold,
                            font: _isArabic ? arabicFontBold : null,
                          ),
                          textDirection: _isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          '${_isArabic ? 'رقم التليفون:' : 'Phone:'} ${prescription.phoneNumber}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            font: _isArabic ? arabicFont : null,
                          ),
                          textDirection: _isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${_isArabic ? 'اسم الطبيب:' : 'Doctor Name:'} ${prescription.doctorName}',
                          style: pw.TextStyle(
                            fontSize: 14, 
                            fontWeight: pw.FontWeight.bold,
                            font: _isArabic ? arabicFontBold : null,
                          ),
                          textDirection: _isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          '${_isArabic ? 'التاريخ:' : 'Date:'} ${_formatDate(prescription.prescriptionDate)}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            font: _isArabic ? arabicFont : null,
                          ),
                          textDirection: _isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 30),
        
        // الأدوية
        pw.Text(
          _isArabic ? 'الأدوية الموصوفة:' : 'Prescribed Medications:',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            font: _isArabic ? arabicFontBold : null,
          ),
          textDirection: _isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
        
        pw.SizedBox(height: 15),
        
        // جدول الأدوية
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            // Header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildPDFTableCell(_isArabic ? 'اسم الدواء' : 'Drug Name', isHeader: true, font: _isArabic ? arabicFontBold : null),
                _buildPDFTableCell(_isArabic ? 'الجرعة' : 'Dosage', isHeader: true, font: _isArabic ? arabicFontBold : null),
                _buildPDFTableCell(_isArabic ? 'المدة' : 'Duration', isHeader: true, font: _isArabic ? arabicFontBold : null),
                _buildPDFTableCell(_isArabic ? 'التعليمات' : 'Instructions', isHeader: true, font: _isArabic ? arabicFontBold : null),
              ],
            ),
            
            // البيانات
            ...prescription.items.map((medication) {
              return pw.TableRow(
                children: [
                  _buildPDFTableCell(medication.drugName, font: arabicFont),
                  _buildPDFTableCell(medication.dosage, font: arabicFont),
                  _buildPDFTableCell('${medication.durationDays} ${_isArabic ? 'يوم' : 'days'}', font: _isArabic ? arabicFont : null),
                  _buildPDFTableCell(medication.instructions.isEmpty 
                      ? (_isArabic ? 'لا توجد تعليمات' : 'No instructions') 
                      : medication.instructions, font: arabicFont),
                ],
              );
            }).toList(),
          ],
        ),
        
        pw.SizedBox(height: 30),
        
        // الملاحظات
        if (prescription.notes.isNotEmpty) ...[
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue200),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _isArabic ? 'ملاحظات:' : 'Notes:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    font: _isArabic ? arabicFontBold : null,
                  ),
                  textDirection: _isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  prescription.notes,
                  style: pw.TextStyle(
                    fontSize: 12,
                    font: arabicFont,
                  ),
                  textDirection: _isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
        ],
        
        // Footer
        pw.Spacer(),
        
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey400),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${_isArabic ? 'تاريخ الطباعة:' : 'Print Date:'} ${_formatDate(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 10, 
                  color: PdfColors.grey600,
                  font: _isArabic ? arabicFont : null,
                ),
                textDirection: _isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
              pw.Text(
                _isArabic ? 'عيادة طبية - نظام إدارة الوصفات' : 'Medical Clinic - Prescription Management',
                style: pw.TextStyle(
                  fontSize: 10, 
                  color: PdfColors.grey600,
                  font: _isArabic ? arabicFont : null,
                ),
                textDirection: _isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // دالة مساعدة لبناء خلايا جدول PDF
  pw.Widget _buildPDFTableCell(String text, {bool isHeader = false, pw.Font? font}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          font: font,
        ),
        textDirection: _isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String title,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final allOption = _isArabic ? 'الكل' : 'All';
    final allItems = [allOption, ...items];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: (value != null && value != allOption) ? primaryBlue : Colors.grey.shade300,
              width: (value != null && value != allOption) ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value ?? allOption,
              isExpanded: true,
              items: allItems.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      color: (value != null && value != allOption && item == value) 
                          ? primaryBlue 
                          : Colors.black87,
                      fontWeight: (value != null && value != allOption && item == value) 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue == allOption) {
                  onChanged(null);
                } else {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showPrescriptionDetails(Prescription prescription) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isArabic ? 'تفاصيل الوصفة الطبية' : 'Prescription Details',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              
              // Patient Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${_isArabic ? 'المريض:' : 'Patient:'} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(prescription.patientName),
                        const SizedBox(width: 20),
                        Text(
                          '${_isArabic ? 'التليفون:' : 'Phone:'} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(prescription.phoneNumber),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${_isArabic ? 'الطبيب:' : 'Doctor:'} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(prescription.doctorName),
                        const SizedBox(width: 20),
                        Text(
                          '${_isArabic ? 'التاريخ:' : 'Date:'} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(_formatDate(prescription.prescriptionDate)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Medications
              Text(
                _isArabic ? 'الأدوية:' : 'Medications:',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    children: prescription.items.map((medication) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medication.drugName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${_isArabic ? 'الجرعة:' : 'Dosage:'} ${medication.dosage}',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${_isArabic ? 'المدة:' : 'Duration:'} ${medication.durationDays} ${_isArabic ? 'يوم' : 'days'}',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            if (medication.instructions.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${_isArabic ? 'التعليمات:' : 'Instructions:'} ${medication.instructions}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              // Notes
              if (prescription.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isArabic ? 'ملاحظات:' : 'Notes:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(prescription.notes),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context); // إغلاق نافذة التفاصيل
                      await _printPrescription(prescription);
                    },
                    icon: const Icon(Icons.print, color: Colors.white),
                    label: Text(
                      _isArabic ? 'طباعة الوصفة' : 'Print Prescription',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPrescriptionDialog() {
    final formKey = GlobalKey<FormState>();
    final TextEditingController phoneNumberController = TextEditingController();
    final TextEditingController doctorController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    
    String patientName = '';
    String displayDoctorName = '';
    bool isPatientLoading = false;
    
    List<PrescriptionItemData> medications = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Container(
            width: 700,
            height: 600,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isArabic ? 'إضافة وصفة طبية جديدة' : 'Add New Prescription',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                Expanded(
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // رقم التليفون
                          Text(
                            _isArabic ? 'رقم التليفون:' : 'Phone Number:',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: phoneNumberController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: _isArabic ? 'أدخل رقم التليفون' : 'Enter phone number',
                              suffixIcon: isPatientLoading 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : null,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return _isArabic ? 'يرجى إدخال رقم التليفون' : 'Please enter phone number';
                              }
                              return null;
                            },
                            onChanged: (value) async {
                              if (value.length >= 10) {
                                setDialogState(() {
                                  isPatientLoading = true;
                                });
                                
                                try {
                                  final patientInfo = await _logic.getPatientAndDoctorInfo(value);
                                  setDialogState(() {
                                    if (patientInfo != null) {
                                      final patient = patientInfo['patient'] as PatientInfo;
                                      patientName = patient.fullName;
                                      displayDoctorName = patientInfo['doctorName'] as String;
                                      doctorController.text = displayDoctorName;
                                    } else {
                                      patientName = '';
                                      displayDoctorName = '';
                                      doctorController.clear();
                                    }
                                    isPatientLoading = false;
                                  });
                                } catch (e) {
                                  setDialogState(() {
                                    patientName = '';
                                    displayDoctorName = '';
                                    doctorController.clear();
                                    isPatientLoading = false;
                                  });
                                }
                              } else {
                                setDialogState(() {
                                  patientName = '';
                                  displayDoctorName = '';
                                  doctorController.clear();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // عرض اسم المريض
                          if (patientName.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                border: Border.all(color: Colors.green.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.person, color: Colors.green.shade600),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_isArabic ? 'المريض:' : 'Patient:'} $patientName',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // اسم الطبيب
                          Text(
                            _isArabic ? 'اسم الطبيب:' : 'Doctor Name:',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: doctorController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: _isArabic ? 'اسم الطبيب (اختياري)' : 'Doctor name (optional)',
                              helperText: _isArabic 
                                  ? 'سيتم استخدام اسم الطبيب من آخر موعد إذا تُرك فارغاً'
                                  : 'Will use doctor name from last appointment if left empty',
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // الأدوية
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isArabic ? 'الأدوية:' : 'Medications:',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _showAddMedicationDialog(medications, setDialogState);
                                },
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: Text(
                                  _isArabic ? 'إضافة دواء' : 'Add Medication',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // قائمة الأدوية
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: medications.isEmpty
                                ? Center(
                                    child: Text(
                                      _isArabic ? 'لا توجد أدوية مضافة' : 'No medications added',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: medications.length,
                                    itemBuilder: (context, index) {
                                      final medication = medications[index];
                                      return Card(
                                        margin: const EdgeInsets.all(8),
                                        child: ListTile(
                                          title: Text(medication.drugName),
                                          subtitle: Text(
                                            '${_isArabic ? 'الجرعة:' : 'Dosage:'} ${medication.dosage} - '
                                            '${_isArabic ? 'المدة:' : 'Duration:'} ${medication.durationDays} ${_isArabic ? 'يوم' : 'days'}',
                                          ),
                                          trailing: IconButton(
                                            onPressed: () {
                                              setDialogState(() {
                                                medications.removeAt(index);
                                              });
                                            },
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 16),
                          
                          // الملاحظات
                          Text(
                            _isArabic ? 'ملاحظات:' : 'Notes:',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: _isArabic ? 'أدخل الملاحظات (اختياري)' : 'Enter notes (optional)',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // أزرار الحفظ والإلغاء
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate() && medications.isNotEmpty && patientName.isNotEmpty) {
                          // حفظ الوصفة
                          final prescriptionId = await _logic.addPrescription(
                            phoneNumber: phoneNumberController.text,
                            doctorName: doctorController.text.isEmpty ? null : doctorController.text,
                            prescriptionDate: DateTime.now(),
                            notes: notesController.text,
                            items: medications,
                          );
                          
                          Navigator.pop(context);
                          
                          if (prescriptionId != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isArabic ? 'تم حفظ الوصفة بنجاح' : 'Prescription saved successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _fetchPrescriptions(); // إعادة تحميل البيانات
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isArabic ? 'فشل في حفظ الوصفة' : 'Failed to save prescription'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else if (medications.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isArabic ? 'يرجى إضافة دواء واحد على الأقل' : 'Please add at least one medication'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else if (patientName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isArabic ? 'يرجى إدخال رقم تليفون صحيح للمريض' : 'Please enter a valid patient phone number'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                      ),
                      child: Text(
                        _isArabic ? 'حفظ الوصفة' : 'Save Prescription',
                        style: const TextStyle(color: Colors.white),
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
  }

  void _showAddMedicationDialog(List<PrescriptionItemData> medications, StateSetter setDialogState) {
    final formKey = GlobalKey<FormState>();
    final TextEditingController drugNameController = TextEditingController();
    final TextEditingController dosageController = TextEditingController();
    final TextEditingController durationController = TextEditingController();
    final TextEditingController instructionsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isArabic ? 'إضافة دواء' : 'Add Medication',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                // اسم الدواء
                TextFormField(
                  controller: drugNameController,
                  decoration: InputDecoration(
                    labelText: _isArabic ? 'اسم الدواء' : 'Drug Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _isArabic ? 'يرجى إدخال اسم الدواء' : 'Please enter drug name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // الجرعة
                TextFormField(
                  controller: dosageController,
                  decoration: InputDecoration(
                    labelText: _isArabic ? 'الجرعة' : 'Dosage',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: _isArabic ? 'مثال: 500 مج' : 'e.g., 500mg',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _isArabic ? 'يرجى إدخال الجرعة' : 'Please enter dosage';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // المدة بالأيام
                TextFormField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _isArabic ? 'المدة (بالأيام)' : 'Duration (Days)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _isArabic ? 'يرجى إدخال المدة' : 'Please enter duration';
                    }
                    if (int.tryParse(value) == null) {
                      return _isArabic ? 'يرجى إدخال رقم صحيح' : 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // التعليمات
                TextFormField(
                  controller: instructionsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: _isArabic ? 'التعليمات' : 'Instructions',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: _isArabic ? 'مثال: قرص واحد ثلاث مرات يومياً' : 'e.g., One tablet three times daily',
                  ),
                ),
                const SizedBox(height: 24),
                
                // أزرار الحفظ والإلغاء
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final medication = PrescriptionItemData(
                            drugName: drugNameController.text,
                            dosage: dosageController.text,
                            durationDays: int.parse(durationController.text),
                            instructions: instructionsController.text,
                          );
                          
                          setDialogState(() {
                            medications.add(medication);
                          });
                          
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                      ),
                      child: Text(
                        _isArabic ? 'إضافة' : 'Add',
                        style: const TextStyle(color: Colors.white),
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
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Row(
          children: [
            AppSidebar(
              parentContext: context,
              selectedPage: 'prescriptions',
              isArabic: _isArabic,
            ),
            Expanded(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Title and Language Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isArabic ? 'إدارة الوصفات الطبية' : 'Prescriptions Management',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isArabic = !_isArabic;
                                    });
                                  },
                                  icon: const Icon(Icons.language, color: primaryBlue),
                                  label: Text(
                                    _isArabic ? 'English' : 'عربي',
                                    style: const TextStyle(color: primaryBlue),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: _showAddPrescriptionDialog,
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  label: Text(
                                    _isArabic ? 'إضافة وصفة جديدة' : 'Add New Prescription',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Search and Filters
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Search Bar
                              SizedBox(
                                width: 300,
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: _isArabic ? 'البحث باسم المريض أو رقم التليفون...' : 'Search by patient name or phone number...',
                                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            onPressed: () {
                                              _searchController.clear();
                                              _filterPrescriptions();
                                            },
                                            icon: const Icon(Icons.clear, color: Colors.grey),
                                          )
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: primaryBlue, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              
                              // Doctor Filter
                              _buildFilterDropdown(
                                title: _isArabic ? 'الطبيب:' : 'Doctor:',
                                value: _selectedDoctor,
                                items: _getUniqueDoctors(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDoctor = value;
                                  });
                                  _filterPrescriptions();
                                },
                              ),
                              const SizedBox(width: 20),
                              
                              // Clear Filters Button
                              if (_hasActiveFilters())
                                ElevatedButton.icon(
                                  onPressed: _clearFilters,
                                  icon: const Icon(Icons.clear_all, color: Colors.white),
                                  label: Text(
                                    _isArabic ? 'مسح الفلاتر' : 'Clear Filters',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade600,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _loading
                          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                          : _filteredPrescriptions.isEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.medical_services_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _hasActiveFilters()
                                          ? (_isArabic ? 'لا توجد وصفات تطابق البحث' : 'No prescriptions match your search')
                                          : (_isArabic ? 'لا توجد وصفات طبية' : 'No prescriptions found'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                )
                              : SingleChildScrollView(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade200,
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                      child: DataTable(
                                        headingRowColor: MaterialStateProperty.all(primaryBlue.withOpacity(0.1)),
                                        columns: [
                                          DataColumn(
                                            label: Text(
                                              _isArabic ? 'اسم المريض' : 'Patient Name',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              _isArabic ? 'رقم التليفون' : 'Phone Number',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              _isArabic ? 'الطبيب' : 'Doctor',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              _isArabic ? 'التاريخ' : 'Date',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              _isArabic ? 'عدد الأدوية' : 'Medications',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              _isArabic ? 'الإجراءات' : 'Actions',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                        rows: _filteredPrescriptions.map((prescription) {
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(prescription.patientName)),
                                              DataCell(Text(prescription.phoneNumber)),
                                              DataCell(Text(prescription.doctorName)),
                                              DataCell(Text(_formatDate(prescription.prescriptionDate))),
                                              DataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: primaryBlue.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    '${prescription.items.length} ${_isArabic ? 'دواء' : 'items'}',
                                                    style: const TextStyle(
                                                      color: primaryBlue,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      onPressed: () => _showPrescriptionDetails(prescription),
                                                      icon: const Icon(Icons.visibility, color: primaryBlue),
                                                      tooltip: _isArabic ? 'عرض التفاصيل' : 'View Details',
                                                    ),
                                                    IconButton(
                                                      onPressed: () async {
                                                        await _printPrescription(prescription);
                                                      },
                                                      icon: const Icon(Icons.print, color: Colors.green),
                                                      tooltip: _isArabic ? 'طباعة' : 'Print',
                                                    ),
                                                    IconButton(
                                                      onPressed: () => _showEditPrescriptionDialog(prescription),
                                                      icon: const Icon(Icons.edit, color: Colors.orange),
                                                      tooltip: _isArabic ? 'تعديل' : 'Edit',
                                                    ),
                                                    IconButton(
                                                      onPressed: () async {
                                                        _showDeleteConfirmationDialog(prescription);
                                                      },
                                                      icon: const Icon(Icons.delete, color: Colors.red),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة لإظهار نافذة تعديل الوصفة
  void _showEditPrescriptionDialog(Prescription prescription) {
    final TextEditingController patientNameController = TextEditingController(text: prescription.patientName);
    final TextEditingController phoneNumberController = TextEditingController(text: prescription.phoneNumber);
    final TextEditingController doctorController = TextEditingController(text: prescription.doctorName);
    final TextEditingController notesController = TextEditingController(text: prescription.notes);
    List<PrescriptionItemData> medications = prescription.items.map((item) => 
      PrescriptionItemData(
        drugName: item.drugName,
        dosage: item.dosage,
        durationDays: item.durationDays,
        instructions: item.instructions,
      )
    ).toList();
    DateTime selectedDate = prescription.prescriptionDate;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    _isArabic ? 'تعديل الوصفة الطبية' : 'Edit Prescription',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.7,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // معلومات المريض
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryBlue.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isArabic ? 'معلومات المريض' : 'Patient Information',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: patientNameController,
                              decoration: InputDecoration(
                                labelText: _isArabic ? 'اسم المريض *' : 'Patient Name *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                prefixIcon: const Icon(Icons.person),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: phoneNumberController,
                              decoration: InputDecoration(
                                labelText: _isArabic ? 'رقم التليفون' : 'Phone Number',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                prefixIcon: const Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // معلومات الطبيب والتاريخ
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: doctorController,
                              decoration: InputDecoration(
                                labelText: _isArabic ? 'اسم الطبيب *' : 'Doctor Name *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                prefixIcon: const Icon(Icons.medical_services),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today),
                                    const SizedBox(width: 8),
                                    Text(_formatDate(selectedDate)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // الملاحظات
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: _isArabic ? 'ملاحظات' : 'Notes',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // قائمة الأدوية
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isArabic ? 'الأدوية' : 'Medications',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showAddMedicationDialog(medications, setModalState);
                            },
                            icon: const Icon(Icons.add),
                            label: Text(_isArabic ? 'إضافة دواء' : 'Add Medication'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // عرض الأدوية
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: medications.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.medication, size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text(
                                        _isArabic ? 'لا توجد أدوية مضافة' : 'No medications added',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: medications.length,
                                itemBuilder: (context, index) {
                                  final medication = medications[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const Icon(Icons.medication, color: primaryBlue),
                                      title: Text(medication.drugName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${medication.dosage} - ${medication.durationDays} ${_isArabic ? 'يوم' : 'days'}\n${medication.instructions}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          setModalState(() {
                                            medications.removeAt(index);
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    // التحقق من المدخلات المطلوبة
                    if (patientNameController.text.trim().isEmpty ||
                        doctorController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isArabic ? 'يرجى ملء جميع الحقول المطلوبة' : 'Please fill all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setModalState(() {
                      isLoading = true;
                    });

                    try {
                      // تحديث الوصفة
                      final success = await _logic.updatePrescription(
                        prescriptionId: prescription.id,
                        phoneNumber: phoneNumberController.text.trim(),
                        doctorName: doctorController.text.trim().isEmpty ? null : doctorController.text.trim(),
                        prescriptionDate: selectedDate,
                        notes: notesController.text.trim(),
                        items: medications,
                      );

                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isArabic ? 'تم تحديث الوصفة بنجاح' : 'Prescription updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _fetchPrescriptions(); // إعادة تحميل البيانات
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isArabic ? 'فشل في تحديث الوصفة' : 'Failed to update prescription'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isArabic ? 'حدث خطأ: $e' : 'Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }

                    setModalState(() {
                      isLoading = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_isArabic ? 'حفظ التغييرات' : 'Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // دالة لإظهار نافذة تأكيد الحذف
  void _showDeleteConfirmationDialog(Prescription prescription) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isDeleting = false;
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    _isArabic ? 'تأكيد الحذف' : 'Confirm Delete',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isArabic ? 'هل أنت متأكد من حذف هذه الوصفة؟' : 'Are you sure you want to delete this prescription?',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.grey[600], size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '${_isArabic ? 'المريض:' : 'Patient:'} ${prescription.patientName}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.medical_services, color: Colors.grey[600], size: 16),
                            const SizedBox(width: 8),
                            Text('${_isArabic ? 'الطبيب:' : 'Doctor:'} ${prescription.doctorName}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey[600], size: 16),
                            const SizedBox(width: 8),
                            Text('${_isArabic ? 'التاريخ:' : 'Date:'} ${_formatDate(prescription.prescriptionDate)}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.medication, color: Colors.grey[600], size: 16),
                            const SizedBox(width: 8),
                            Text('${_isArabic ? 'عدد الأدوية:' : 'Medications:'} ${prescription.items.length}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isArabic ? '⚠️ تحذير: هذا الإجراء لا يمكن التراجع عنه!' : '⚠️ Warning: This action cannot be undone!',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: isDeleting ? null : () async {
                    setModalState(() {
                      isDeleting = true;
                    });

                    try {
                      final success = await _logic.deletePrescription(prescription.id);
                      
                      Navigator.pop(context);
                      
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(_isArabic ? 'تم حذف الوصفة بنجاح' : 'Prescription deleted successfully'),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        _fetchPrescriptions(); // إعادة تحميل البيانات
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(_isArabic ? 'فشل في حذف الوصفة' : 'Failed to delete prescription'),
                              ],
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(_isArabic ? 'حدث خطأ: $e' : 'Error: $e'),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }

                    setModalState(() {
                      isDeleting = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.delete, size: 18, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(_isArabic ? 'حذف' : 'Delete'),
                          ],
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
