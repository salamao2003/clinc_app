import 'package:supabase_flutter/supabase_flutter.dart';

// Model لخدمة في الفاتورة
class InvoiceService {
  final String? id;
  final String invoiceId;
  final String serviceName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  InvoiceService({
    this.id,
    required this.invoiceId,
    required this.serviceName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory InvoiceService.fromJson(Map<String, dynamic> json) {
    return InvoiceService(
      id: json['id'],
      invoiceId: json['invoice_id'],
      serviceName: json['service_name'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'invoice_id': invoiceId,
      'service_name': serviceName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}

// Model للفاتورة
class Invoice {
  final String id;
  final String? patientId;
  final String patientName;
  final String phoneNumber;
  final String doctorName;
  final double totalAmount;
  final DateTime invoiceDate;
  final String paymentStatus; // 'Paid', 'Unpaid', 'Partially Paid'
  final String? paymentMethod; // 'Cash', 'Card', 'Bank Transfer', 'Insurance'
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<InvoiceService> services;

  Invoice({
    required this.id,
    this.patientId,
    required this.patientName,
    required this.phoneNumber,
    required this.doctorName,
    required this.totalAmount,
    required this.invoiceDate,
    required this.paymentStatus,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.services = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      patientId: json['patient_id'],
      patientName: json['patient_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      // التعامل مع العمود القديم والجديد
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 
                   (json['amount'] as num?)?.toDouble() ?? 0.0,
      invoiceDate: DateTime.parse(json['invoice_date']),
      paymentStatus: json['payment_status'] ?? 'Unpaid',
      paymentMethod: json['payment_method'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      services: [], // سيتم جلب الخدمات في استعلام منفصل
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'phone_number': phoneNumber,
      'doctor_name': doctorName,
      'total_amount': totalAmount,
      'invoice_date': invoiceDate.toIso8601String().split('T')[0],
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // إنشاء نسخة محدثة من الفاتورة مع خدمات جديدة
  Invoice copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? phoneNumber,
    String? doctorName,
    double? totalAmount,
    DateTime? invoiceDate,
    String? paymentStatus,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<InvoiceService>? services,
  }) {
    return Invoice(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      doctorName: doctorName ?? this.doctorName,
      totalAmount: totalAmount ?? this.totalAmount,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      services: services ?? this.services,
    );
  }
}

// Model لمعلومات المريض المختصرة
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
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class BillingLogic {
  final SupabaseClient _supabase = Supabase.instance.client;

  // جلب جميع الفواتير مع خدماتها
  Future<List<Invoice>> fetchInvoices() async {
    try {
      final response = await _supabase
          .from('invoices')
          .select('*')
          .order('created_at', ascending: false);

      List<Invoice> invoices = (response as List)
          .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
          .toList();

      // جلب خدمات كل فاتورة
      for (int i = 0; i < invoices.length; i++) {
        final services = await _fetchInvoiceServices(invoices[i].id);
        invoices[i] = invoices[i].copyWith(services: services);
      }

      return invoices;
    } catch (e) {
      print('Error fetching invoices: $e');
      throw Exception('فشل في جلب الفواتير');
    }
  }

  // جلب خدمات فاتورة محددة
  Future<List<InvoiceService>> _fetchInvoiceServices(String invoiceId) async {
    try {
      final response = await _supabase
          .from('invoice_services')
          .select('*')
          .eq('invoice_id', invoiceId);

      return (response as List)
          .map((json) => InvoiceService.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching invoice services: $e');
      return [];
    }
  }

  // جلب فاتورة واحدة مع خدماتها
  Future<Invoice?> getInvoiceWithServices(String invoiceId) async {
    try {
      final invoiceResponse = await _supabase
          .from('invoices')
          .select('*')
          .eq('id', invoiceId)
          .maybeSingle();

      if (invoiceResponse == null) return null;

      final invoice = Invoice.fromJson(invoiceResponse);
      final services = await _fetchInvoiceServices(invoiceId);

      return invoice.copyWith(services: services);
    } catch (e) {
      print('Error getting invoice with services: $e');
      return null;
    }
  }

  // البحث في الفواتير
  Future<List<Invoice>> searchInvoices({
    String? patientName,
    String? phoneNumber,
    String? doctorName,
    String? paymentStatus,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _supabase.from('invoices').select('*');

      // تطبيق الفلاتر
      if (patientName != null && patientName.isNotEmpty) {
        query = query.ilike('patient_name', '%$patientName%');
      }

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        query = query.ilike('phone_number', '%$phoneNumber%');
      }

      if (doctorName != null && doctorName.isNotEmpty) {
        query = query.ilike('doctor_name', '%$doctorName%');
      }

      if (paymentStatus != null && paymentStatus.isNotEmpty) {
        query = query.eq('payment_status', paymentStatus);
      }

      if (fromDate != null) {
        query = query.gte('invoice_date', fromDate.toIso8601String().split('T')[0]);
      }

      if (toDate != null) {
        query = query.lte('invoice_date', toDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('created_at', ascending: false);

      List<Invoice> invoices = (response as List)
          .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
          .toList();

      // جلب خدمات كل فاتورة
      for (int i = 0; i < invoices.length; i++) {
        final services = await _fetchInvoiceServices(invoices[i].id);
        invoices[i] = invoices[i].copyWith(services: services);
      }

      return invoices;
    } catch (e) {
      print('Error searching invoices: $e');
      throw Exception('فشل في البحث عن الفواتير');
    }
  }

  // جلب بيانات المريض من رقم التليفون
  Future<PatientInfo?> getPatientByPhone(String phoneNumber) async {
    try {
      final response = await _supabase
          .from('patients')
          .select('id, full_name, phone_number, email')
          .eq('phone_number', phoneNumber)
          .maybeSingle();

      if (response == null) return null;

      return PatientInfo.fromJson(response);
    } catch (e) {
      print('Error getting patient by phone: $e');
      return null;
    }
  }

  // جلب اسم الدكتور من آخر موعد للمريض
  Future<String> getLastDoctorForPatient(String patientId) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('doctor_name')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response?['doctor_name'] ?? '';
    } catch (e) {
      print('Error getting last doctor: $e');
      return '';
    }
  }

  // جلب بيانات المريض والدكتور مجمعة
  Future<Map<String, dynamic>?> getPatientAndDoctorInfo(String phoneNumber) async {
    final patient = await getPatientByPhone(phoneNumber);
    if (patient == null) return null;

    final doctorName = await getLastDoctorForPatient(patient.id);

    return {
      'patient': patient,
      'doctorName': doctorName,
    };
  }

  // إضافة فاتورة جديدة مع خدمات متعددة
  Future<bool> addInvoice({
    required String phoneNumber,
    String? doctorName,
    required List<InvoiceService> services,
    required DateTime invoiceDate,
    required String paymentStatus,
    String? paymentMethod,
    String? notes,
  }) async {
    try {
      // التحقق من وجود خدمات
      if (services.isEmpty) {
        throw Exception('يجب إضافة خدمة واحدة على الأقل');
      }

      // جلب بيانات المريض والدكتور
      final patientInfo = await getPatientAndDoctorInfo(phoneNumber);
      if (patientInfo == null) {
        throw Exception('لم يتم العثور على مريض بهذا الرقم');
      }

      final patient = patientInfo['patient'] as PatientInfo;
      final lastDoctorName = patientInfo['doctorName'] as String;

      // استخدام اسم الدكتور المرسل أو الأخير من المواعيد
      final finalDoctorName = doctorName?.isNotEmpty == true ? doctorName! : lastDoctorName;

      // حساب المجموع الكلي
      double totalAmount = services.fold(0, (sum, service) => sum + service.totalPrice);

      // إدراج الفاتورة أولاً
      final invoiceResponse = await _supabase.from('invoices').insert({
        'patient_id': patient.id,
        'patient_name': patient.fullName,
        'phone_number': patient.phoneNumber,
        'doctor_name': finalDoctorName,
        'amount': totalAmount,  // استخدام العمود القديم
        'invoice_date': invoiceDate.toIso8601String().split('T')[0],
        'payment_status': paymentStatus,
        'payment_method': paymentMethod,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      final invoiceId = invoiceResponse['id'] as String;

      // إدراج خدمات الفاتورة
      final servicesData = services.map((service) => {
        'invoice_id': invoiceId,
        'service_name': service.serviceName,
        'quantity': service.quantity,
        'unit_price': service.unitPrice,
        'total_price': service.totalPrice,
      }).toList();

      await _supabase.from('invoice_services').insert(servicesData);

      print('Invoice added successfully');
      return true;
    } catch (e) {
      print('Error adding invoice: $e');
      throw Exception('فشل في إضافة الفاتورة: ${e.toString()}');
    }
  }

  // تعديل فاتورة موجودة مع خدماتها
  Future<bool> updateInvoice({
    required String invoiceId,
    required String phoneNumber,
    String? doctorName,
    required List<InvoiceService> services,
    required DateTime invoiceDate,
    required String paymentStatus,
    String? paymentMethod,
    String? notes,
  }) async {
    try {
      // التحقق من وجود خدمات
      if (services.isEmpty) {
        throw Exception('يجب إضافة خدمة واحدة على الأقل');
      }

      // جلب بيانات المريض والدكتور
      final patientInfo = await getPatientAndDoctorInfo(phoneNumber);
      if (patientInfo == null) {
        throw Exception('لم يتم العثور على مريض بهذا الرقم');
      }

      final patient = patientInfo['patient'] as PatientInfo;
      final lastDoctorName = patientInfo['doctorName'] as String;

      // استخدام اسم الدكتور المرسل أو الأخير من المواعيد
      final finalDoctorName = doctorName?.isNotEmpty == true ? doctorName! : lastDoctorName;

      // حساب المجموع الكلي
      double totalAmount = services.fold(0, (sum, service) => sum + service.totalPrice);

      // تحديث الفاتورة
      await _supabase
          .from('invoices')
          .update({
            'patient_id': patient.id,
            'patient_name': patient.fullName,
            'phone_number': patient.phoneNumber,
            'doctor_name': finalDoctorName,
            'amount': totalAmount,  // استخدام العمود القديم
            'invoice_date': invoiceDate.toIso8601String().split('T')[0],
            'payment_status': paymentStatus,
            'payment_method': paymentMethod,
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invoiceId);

      // حذف الخدمات القديمة
      await _supabase
          .from('invoice_services')
          .delete()
          .eq('invoice_id', invoiceId);

      // إدراج الخدمات الجديدة
      final servicesData = services.map((service) => {
        'invoice_id': invoiceId,
        'service_name': service.serviceName,
        'quantity': service.quantity,
        'unit_price': service.unitPrice,
        'total_price': service.totalPrice,
      }).toList();

      await _supabase.from('invoice_services').insert(servicesData);

      print('Invoice updated successfully');
      return true;
    } catch (e) {
      print('Error updating invoice: $e');
      throw Exception('فشل في تحديث الفاتورة: ${e.toString()}');
    }
  }

  // حذف فاتورة مع خدماتها
  Future<bool> deleteInvoice(String invoiceId) async {
    try {
      // حذف خدمات الفاتورة أولاً
      await _supabase
          .from('invoice_services')
          .delete()
          .eq('invoice_id', invoiceId);

      // حذف الفاتورة
      await _supabase
          .from('invoices')
          .delete()
          .eq('id', invoiceId);

      print('Invoice deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting invoice: $e');
      return false;
    }
  }

  // إحصائيات الفواتير
  Future<Map<String, dynamic>> getInvoiceStatistics() async {
    try {
      final response = await _supabase
          .from('invoices')
          .select('amount, payment_status');  // استخدام العمود القديم

      final invoices = response as List;
      
      double totalAmount = 0;
      double paidAmount = 0;
      double unpaidAmount = 0;
      int totalInvoices = invoices.length;
      int paidInvoices = 0;
      int unpaidInvoices = 0;

      for (var invoice in invoices) {
        final amount = (invoice['amount'] as num).toDouble();  // استخدام العمود القديم
        final status = invoice['payment_status'] as String;

        totalAmount += amount;

        if (status == 'Paid') {
          paidAmount += amount;
          paidInvoices++;
        } else {
          unpaidAmount += amount;
          unpaidInvoices++;
        }
      }

      return {
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'unpaidAmount': unpaidAmount,
        'totalInvoices': totalInvoices,
        'paidInvoices': paidInvoices,
        'unpaidInvoices': unpaidInvoices,
      };
    } catch (e) {
      print('Error getting invoice statistics: $e');
      return {
        'totalAmount': 0.0,
        'paidAmount': 0.0,
        'unpaidAmount': 0.0,
        'totalInvoices': 0,
        'paidInvoices': 0,
        'unpaidInvoices': 0,
      };
    }
  }

  // دوال مساعدة لإدارة الخدمات
  
  // إضافة خدمة لفاتورة موجودة
  Future<bool> addServiceToInvoice(String invoiceId, InvoiceService service) async {
    try {
      // إدراج الخدمة الجديدة
      await _supabase.from('invoice_services').insert({
        'invoice_id': invoiceId,
        'service_name': service.serviceName,
        'quantity': service.quantity,
        'unit_price': service.unitPrice,
        'total_price': service.totalPrice,
      });

      // تحديث المجموع الكلي للفاتورة
      await _updateInvoiceTotalAmount(invoiceId);

      return true;
    } catch (e) {
      print('Error adding service to invoice: $e');
      return false;
    }
  }

  // حذف خدمة من فاتورة
  Future<bool> removeServiceFromInvoice(String serviceId) async {
    try {
      // جلب معرف الفاتورة قبل الحذف
      final serviceResponse = await _supabase
          .from('invoice_services')
          .select('invoice_id')
          .eq('id', serviceId)
          .maybeSingle();

      if (serviceResponse == null) return false;

      final invoiceId = serviceResponse['invoice_id'] as String;

      // حذف الخدمة
      await _supabase
          .from('invoice_services')
          .delete()
          .eq('id', serviceId);

      // تحديث المجموع الكلي للفاتورة
      await _updateInvoiceTotalAmount(invoiceId);

      return true;
    } catch (e) {
      print('Error removing service from invoice: $e');
      return false;
    }
  }

  // تحديث المجموع الكلي للفاتورة
  Future<void> _updateInvoiceTotalAmount(String invoiceId) async {
    try {
      final servicesResponse = await _supabase
          .from('invoice_services')
          .select('total_price')
          .eq('invoice_id', invoiceId);

      double totalAmount = 0;
      for (var service in servicesResponse as List) {
        totalAmount += (service['total_price'] as num).toDouble();
      }

      await _supabase
          .from('invoices')
          .update({
            'amount': totalAmount,  // استخدام العمود القديم
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invoiceId);
    } catch (e) {
      print('Error updating invoice total amount: $e');
    }
  }
}