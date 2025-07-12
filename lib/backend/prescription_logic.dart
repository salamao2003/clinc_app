import 'package:supabase_flutter/supabase_flutter.dart';

// Model للوصفة الطبية الأساسية
class Prescription {
  final String id;
  final String doctorName;
  final DateTime prescriptionDate;
  final String notes;
  final List<PrescriptionItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  // إضافة patient_id للربط مع جدول patients
  final String? patientId;
  final String patientName;
  final String phoneNumber;

  Prescription({
    required this.id,
    required this.doctorName,
    required this.prescriptionDate,
    required this.notes,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.patientId,
    required this.patientName,
    required this.phoneNumber,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      doctorName: json['doctor_name'] ?? '',
      prescriptionDate: DateTime.parse(json['prescription_date']),
      notes: json['notes'] ?? '',
      items: (json['prescription_items'] as List<dynamic>?)
          ?.map((item) => PrescriptionItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      // جلب بيانات المريض من العلاقة مع جدول patients
      patientId: json['patient_id'],
      patientName: json['patients']?['full_name'] ?? json['patient_name'] ?? '',
      phoneNumber: json['patients']?['phone_number'] ?? json['phone_number'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_name': doctorName,
      'prescription_date': prescriptionDate.toIso8601String().split('T')[0],
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Model لأدوية الوصفة
class PrescriptionItem {
  final String id;
  final String prescriptionId;
  final String drugName;
  final String dosage;
  final int durationDays;
  final String instructions;
  final DateTime createdAt;

  PrescriptionItem({
    required this.id,
    required this.prescriptionId,
    required this.drugName,
    required this.dosage,
    required this.durationDays,
    required this.instructions,
    required this.createdAt,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      id: json['id'],
      prescriptionId: json['prescription_id'],
      drugName: json['drug_name'],
      dosage: json['dosage'],
      durationDays: json['duration_days'],
      instructions: json['instructions'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prescription_id': prescriptionId,
      'drug_name': drugName,
      'dosage': dosage,
      'duration_days': durationDays,
      'instructions': instructions,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Model مبسط للمرضى
class PatientInfo {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;

  PatientInfo({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      id: json['id'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      email: json['email'] ?? '',
    );
  }
}

// الفئة الرئيسية لمنطق الوصفات الطبية
class PrescriptionLogic {
  final _supabase = Supabase.instance.client;

  // جلب جميع الوصفات مع تفاصيل الأدوية وبيانات المرضى
  Future<List<Prescription>> fetchPrescriptions() async {
    try {
      final response = await _supabase
          .from('prescriptions')
          .select('''
            *,
            patients!inner (
              full_name,
              phone_number
            ),
            prescription_items (
              id,
              prescription_id,
              drug_name,
              dosage,
              duration_days,
              instructions,
              created_at
            )
          ''')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Prescription.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching prescriptions: $e');
      // إرجاع بيانات وهمية في حالة الخطأ للاختبار
      return _getDummyPrescriptions();
    }
  }

  // جلب وصفة واحدة بتفاصيلها
  Future<Prescription?> fetchPrescriptionById(String prescriptionId) async {
    try {
      final response = await _supabase
          .from('prescriptions')
          .select('''
            *,
            patients!inner (
              full_name,
              phone_number
            ),
            prescription_items (
              id,
              prescription_id,
              drug_name,
              dosage,
              duration_days,
              instructions,
              created_at
            )
          ''')
          .eq('id', prescriptionId)
          .single();

      return Prescription.fromJson(response);
    } catch (e) {
      print('Error fetching prescription by ID: $e');
      return null;
    }
  }

  // جلب جميع المرضى (للاختيار عند إنشاء وصفة جديدة)
  Future<List<PatientInfo>> fetchPatients() async {
    try {
      final response = await _supabase
          .from('patients')
          .select('id, full_name, phone_number, email')
          .eq('is_active', true)
          .order('full_name');

      return (response as List)
          .map((json) => PatientInfo.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching patients: $e');
      return [];
    }
  }

  // جلب وصفات مريض معين
  Future<List<Prescription>> fetchPrescriptionsByPatientId(String patientId) async {
    try {
      final response = await _supabase
          .from('prescriptions')
          .select('''
            *,
            patients!inner (
              full_name,
              phone_number
            ),
            prescription_items (
              id,
              prescription_id,
              drug_name,
              dosage,
              duration_days,
              instructions,
              created_at
            )
          ''')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Prescription.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching prescriptions by patient ID: $e');
      return [];
    }
  }

  // البحث في الوصفات
  Future<List<Prescription>> searchPrescriptions({
    String? patientName,
    String? phoneNumber,
    String? doctorName,
    DateTime? fromDate,
    DateTime? toDate,
    String? drugName,
  }) async {
    try {
      var query = _supabase
          .from('prescriptions')
          .select('''
            *,
            patients!inner (
              full_name,
              phone_number
            ),
            prescription_items (
              id,
              prescription_id,
              drug_name,
              dosage,
              duration_days,
              instructions,
              created_at
            )
          ''');

      // تطبيق الفلاتر
      if (doctorName != null && doctorName.isNotEmpty) {
        query = query.ilike('doctor_name', '%$doctorName%');
      }

      if (fromDate != null) {
        query = query.gte('prescription_date', fromDate.toIso8601String().split('T')[0]);
      }

      if (toDate != null) {
        query = query.lte('prescription_date', toDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('created_at', ascending: false);

      var prescriptions = (response as List)
          .map((json) => Prescription.fromJson(json as Map<String, dynamic>))
          .toList();

      // فلترة محلية للبحث في اسم المريض أو رقم التليفون
      if (patientName != null && patientName.isNotEmpty) {
        prescriptions = prescriptions.where((prescription) {
          return prescription.patientName.toLowerCase().contains(patientName.toLowerCase());
        }).toList();
      }

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        prescriptions = prescriptions.where((prescription) {
          return prescription.phoneNumber.contains(phoneNumber);
        }).toList();
      }

      // فلترة حسب اسم الدواء إذا كان مطلوباً
      if (drugName != null && drugName.isNotEmpty) {
        prescriptions = prescriptions.where((prescription) {
          return prescription.items.any((item) =>
              item.drugName.toLowerCase().contains(drugName.toLowerCase()));
        }).toList();
      }

      return prescriptions;
    } catch (e) {
      print('Error searching prescriptions: $e');
      return [];
    }
  }

  // إضافة وصفة جديدة
  Future<String?> addPrescription({
    required String phoneNumber,
    String? doctorName,
    required DateTime prescriptionDate,
    required String notes,
    required List<PrescriptionItemData> items,
  }) async {
    try {
      // جلب بيانات المريض والدكتور
      final patientInfo = await getPatientAndDoctorInfo(phoneNumber);
      if (patientInfo == null) {
        print('Patient not found with phone number: $phoneNumber');
        return null;
      }

      final patient = patientInfo['patient'] as PatientInfo;
      final lastDoctorName = patientInfo['doctorName'] as String;

      // استخدام اسم الدكتور المرسل أو الأخير من المواعيد
      final finalDoctorName = doctorName?.isNotEmpty == true ? doctorName! : lastDoctorName;

      // إضافة الوصفة الأساسية
      final prescriptionResponse = await _supabase
          .from('prescriptions')
          .insert({
            'patient_id': patient.id,
            'patient_name': patient.fullName,
            'phone_number': patient.phoneNumber,
            'doctor_name': finalDoctorName,
            'prescription_date': prescriptionDate.toIso8601String().split('T')[0],
            'notes': notes,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final prescriptionId = prescriptionResponse['id'] as String;

      // إضافة أدوية الوصفة
      if (items.isNotEmpty) {
        final itemsData = items.map((item) => {
          'prescription_id': prescriptionId,
          'drug_name': item.drugName,
          'dosage': item.dosage,
          'duration_days': item.durationDays,
          'instructions': item.instructions,
          'created_at': DateTime.now().toIso8601String(),
        }).toList();

        await _supabase.from('prescription_items').insert(itemsData);
      }

      return prescriptionId;
    } catch (e) {
      print('Error adding prescription: $e');
      return null;
    }
  }

  // تعديل وصفة موجودة
  Future<bool> updatePrescription({
    required String prescriptionId,
    required String phoneNumber,
    String? doctorName,
    required DateTime prescriptionDate,
    required String notes,
    required List<PrescriptionItemData> items,
  }) async {
    try {
      // جلب بيانات المريض والدكتور
      final patientInfo = await getPatientAndDoctorInfo(phoneNumber);
      if (patientInfo == null) {
        print('Patient not found with phone number: $phoneNumber');
        return false;
      }

      final patient = patientInfo['patient'] as PatientInfo;
      final lastDoctorName = patientInfo['doctorName'] as String;

      // استخدام اسم الدكتور المرسل أو الأخير من المواعيد
      final finalDoctorName = doctorName?.isNotEmpty == true ? doctorName! : lastDoctorName;

      // تحديث الوصفة الأساسية
      await _supabase
          .from('prescriptions')
          .update({
            'patient_id': patient.id,
            'patient_name': patient.fullName,
            'phone_number': patient.phoneNumber,
            'doctor_name': finalDoctorName,
            'prescription_date': prescriptionDate.toIso8601String().split('T')[0],
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', prescriptionId);

      // حذف الأدوية القديمة
      await _supabase
          .from('prescription_items')
          .delete()
          .eq('prescription_id', prescriptionId);

      // إضافة الأدوية الجديدة
      if (items.isNotEmpty) {
        final itemsData = items.map((item) => {
          'prescription_id': prescriptionId,
          'drug_name': item.drugName,
          'dosage': item.dosage,
          'duration_days': item.durationDays,
          'instructions': item.instructions,
          'created_at': DateTime.now().toIso8601String(),
        }).toList();

        await _supabase.from('prescription_items').insert(itemsData);
      }

      return true;
    } catch (e) {
      print('Error updating prescription: $e');
      return false;
    }
  }

  // حذف وصفة
  Future<bool> deletePrescription(String prescriptionId) async {
    try {
      print('Starting prescription deletion for ID: $prescriptionId');
      
      // حذف الأدوية أولاً (بسبب الـ Foreign Key)
      final itemsDeleteResult = await _supabase
          .from('prescription_items')
          .delete()
          .eq('prescription_id', prescriptionId);
      
      print('Prescription items deleted: $itemsDeleteResult');

      // حذف الوصفة
      final prescriptionDeleteResult = await _supabase
          .from('prescriptions')
          .delete()
          .eq('id', prescriptionId);
      
      print('Prescription deleted: $prescriptionDeleteResult');
      print('Prescription deletion completed successfully for ID: $prescriptionId');

      return true;
    } catch (e) {
      print('Error deleting prescription: $e');
      return false;
    }
  }

  // حذف دواء واحد من الوصفة
  Future<bool> deletePrescriptionItem(String itemId) async {
    try {
      await _supabase
          .from('prescription_items')
          .delete()
          .eq('id', itemId);

      return true;
    } catch (e) {
      print('Error deleting prescription item: $e');
      return false;
    }
  }

  // إحصائيات الوصفات
  Future<Map<String, dynamic>> getPrescriptionStats() async {
    try {
      // إجمالي عدد الوصفات
      final totalPrescriptions = await _supabase
          .from('prescriptions')
          .select('id');

      // الوصفات اليوم
      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayPrescriptions = await _supabase
          .from('prescriptions')
          .select('id')
          .eq('prescription_date', today);

      // الوصفات هذا الشهر
      final thisMonth = DateTime(DateTime.now().year, DateTime.now().month, 1)
          .toIso8601String().split('T')[0];
      final monthPrescriptions = await _supabase
          .from('prescriptions')
          .select('id')
          .gte('prescription_date', thisMonth);

      // أكثر الأطباء نشاطاً
      final doctorStats = await _supabase
          .from('prescriptions')
          .select('doctor_name')
          .not('doctor_name', 'is', null);

      // أكثر الأدوية استخداماً
      final drugStats = await _supabase
          .from('prescription_items')
          .select('drug_name');

      return {
        'totalPrescriptions': totalPrescriptions.length,
        'todayPrescriptions': todayPrescriptions.length,
        'monthPrescriptions': monthPrescriptions.length,
        'doctorStats': _countFrequency(doctorStats.map((d) => d['doctor_name'] as String).toList()),
        'drugStats': _countFrequency(drugStats.map((d) => d['drug_name'] as String).toList()),
      };
    } catch (e) {
      print('Error getting prescription stats: $e');
      return {
        'totalPrescriptions': 0,
        'todayPrescriptions': 0,
        'monthPrescriptions': 0,
        'doctorStats': <String, int>{},
        'drugStats': <String, int>{},
      };
    }
  }

  // دالة مساعدة لحساب التكرارات
  Map<String, int> _countFrequency(List<String> items) {
    final Map<String, int> frequency = {};
    for (final item in items) {
      frequency[item] = (frequency[item] ?? 0) + 1;
    }
    return Map.fromEntries(
      frequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
    );
  }

  // دالة لإرجاع بيانات وهمية للاختبار (عند فشل الاتصال بقاعدة البيانات)
  List<Prescription> _getDummyPrescriptions() {
    return [
      Prescription(
        id: '1',
        patientId: 'patient-1',
        doctorName: 'د. محمد أحمد',
        prescriptionDate: DateTime.now().subtract(const Duration(days: 1)),
        notes: 'يُنصح بتناول الدواء بعد الطعام',
        patientName: 'أحمد محمد علي',
        phoneNumber: '01234567890',
        items: [
          PrescriptionItem(
            id: '1',
            prescriptionId: '1',
            drugName: 'أموكسيسيلين 500 مج',
            dosage: '500 مج',
            durationDays: 7,
            instructions: 'كبسولة واحدة ثلاث مرات يومياً',
            createdAt: DateTime.now(),
          ),
          PrescriptionItem(
            id: '2',
            prescriptionId: '1',
            drugName: 'باراسيتامول 500 مج',
            dosage: '500 مج',
            durationDays: 5,
            instructions: 'قرص واحد عند الحاجة للألم',
            createdAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Prescription(
        id: '2',
        patientId: 'patient-2',
        doctorName: 'د. سارة محمود',
        prescriptionDate: DateTime.now().subtract(const Duration(days: 3)),
        notes: 'مراجعة بعد أسبوع',
        patientName: 'فاطمة أحمد محمد',
        phoneNumber: '01123456789',
        items: [
          PrescriptionItem(
            id: '3',
            prescriptionId: '2',
            drugName: 'فيتامين د 1000 وحدة',
            dosage: '1000 IU',
            durationDays: 30,
            instructions: 'قرص واحد يومياً مع الإفطار',
            createdAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  // دوال مساعدة لجلب بيانات المريض ومعلومات الدكتور
  
  // جلب بيانات المريض من رقم التليفون
  Future<PatientInfo?> getPatientByPhone(String phoneNumber) async {
    try {
      final response = await _supabase
          .from('patients')
          .select('id, full_name, phone_number, email')
          .eq('phone_number', phoneNumber)
          .single();

      return PatientInfo.fromJson(response);
    } catch (e) {
      print('Error getting patient by phone: $e');
      return null;
    }
  }

  // جلب اسم الدكتور من آخر موعد للمريض
  Future<String?> getLastDoctorForPatient(String patientId) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('doctor_name')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first['doctor_name'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting last doctor for patient: $e');
      return null;
    }
  }

  // جلب معلومات المريض والدكتور معاً من رقم التليفون
  Future<Map<String, dynamic>?> getPatientAndDoctorInfo(String phoneNumber) async {
    try {
      // جلب بيانات المريض
      final patient = await getPatientByPhone(phoneNumber);
      if (patient == null) return null;

      // جلب اسم الدكتور من آخر موعد
      final doctorName = await getLastDoctorForPatient(patient.id);

      return {
        'patient': patient,
        'doctorName': doctorName ?? '',
      };
    } catch (e) {
      print('Error getting patient and doctor info: $e');
      return null;
    }
  }
}

// Class لبيانات الدواء عند الإضافة/التعديل
class PrescriptionItemData {
  final String drugName;
  final String dosage;
  final int durationDays;
  final String instructions;

  PrescriptionItemData({
    required this.drugName,
    required this.dosage,
    required this.durationDays,
    required this.instructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'drug_name': drugName,
      'dosage': dosage,
      'duration_days': durationDays,
      'instructions': instructions,
    };
  }
}
