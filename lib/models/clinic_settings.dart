class ClinicSettings {
  final String id;
  final String userId;
  final String clinicName;
  final String clinicAddress;
  final String clinicPhone;
  final String clinicEmail;
  final String clinicWebsite;
  final String clinicLogoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClinicSettings({
    required this.id,
    required this.userId,
    required this.clinicName,
    this.clinicAddress = '',
    this.clinicPhone = '',
    this.clinicEmail = '',
    this.clinicWebsite = '',
    this.clinicLogoUrl = '',
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor لإنشاء object من JSON
  factory ClinicSettings.fromJson(Map<String, dynamic> json) {
    return ClinicSettings(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      clinicName: json['clinic_name'] ?? '',
      clinicAddress: json['clinic_address'] ?? '',
      clinicPhone: json['clinic_phone'] ?? '',
      clinicEmail: json['clinic_email'] ?? '',
      clinicWebsite: json['clinic_website'] ?? '',
      clinicLogoUrl: json['clinic_logo_url'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // تحويل Object إلى JSON للإرسال لقاعدة البيانات
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'clinic_name': clinicName,
      'clinic_address': clinicAddress,
      'clinic_phone': clinicPhone,
      'clinic_email': clinicEmail,
      'clinic_website': clinicWebsite,
      'clinic_logo_url': clinicLogoUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // إنشاء نسخة جديدة مع تغيير بعض القيم
  ClinicSettings copyWith({
    String? id,
    String? userId,
    String? clinicName,
    String? clinicAddress,
    String? clinicPhone,
    String? clinicEmail,
    String? clinicWebsite,
    String? clinicLogoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      clinicPhone: clinicPhone ?? this.clinicPhone,
      clinicEmail: clinicEmail ?? this.clinicEmail,
      clinicWebsite: clinicWebsite ?? this.clinicWebsite,
      clinicLogoUrl: clinicLogoUrl ?? this.clinicLogoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // تحقق من صحة البيانات الأساسية
  bool get isValid {
    return clinicName.isNotEmpty;
  }

  // تحقق من صحة البريد الإلكتروني
  bool get isEmailValid {
    if (clinicEmail.isEmpty) return true; // اختياري
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(clinicEmail);
  }

  // تحقق من صحة رقم التليفون
  bool get isPhoneValid {
    if (clinicPhone.isEmpty) return true; // اختياري
    return RegExp(r'^[0-9+\-\s\(\)]{10,15}$').hasMatch(clinicPhone);
  }

  // تحقق من صحة الموقع الإلكتروني
  bool get isWebsiteValid {
    if (clinicWebsite.isEmpty) return true; // اختياري
    return RegExp(r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$')
        .hasMatch(clinicWebsite);
  }

  // تحقق من جميع البيانات
  bool get isAllDataValid {
    return isValid && isEmailValid && isPhoneValid && isWebsiteValid;
  }

  @override
  String toString() {
    return 'ClinicSettings(id: $id, clinicName: $clinicName, userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClinicSettings && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
