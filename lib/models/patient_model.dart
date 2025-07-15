// lib/models/patient_model.dart
class Patient {
  final String id;
  final String fullName;
  final String gender;
  final String phoneNumber;
  final String email;
  final DateTime dateOfBirth;
  final DateTime? lastVisitDate;
  final String address;
  final String emergencyContact;
  final String emergencyPhone;
  final String medicalHistory;
  final String allergies;
  final String bloodType;
  final String notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  Patient({
    required this.id,
    required this.fullName,
    required this.gender,
    required this.phoneNumber,
    required this.email,
    required this.dateOfBirth,
    this.lastVisitDate,
    required this.address,
    required this.emergencyContact,
    this.emergencyPhone = '',
    this.medicalHistory = '',
    this.allergies = '',
    this.bloodType = '',
    this.notes = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = 'main_user',
  });

  // Factory constructor for creating Patient from JSON (Local SQLite format)
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : DateTime.now(),
      lastVisitDate: json['last_visit_date'] != null 
          ? DateTime.parse(json['last_visit_date']) 
          : null,
      address: json['address']?.toString() ?? '',
      emergencyContact: json['emergency_contact']?.toString() ?? '',
      emergencyPhone: json['emergency_phone']?.toString() ?? '',
      medicalHistory: json['medical_history']?.toString() ?? '',
      allergies: json['allergies']?.toString() ?? '',
      bloodType: json['blood_type']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      isActive: (json['is_active'] == 1) || (json['is_active'] == true),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      createdBy: json['created_by']?.toString() ?? 'main_user',
    );
  }

  // Convert Patient to JSON (Local SQLite format)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'gender': gender,
      'phone_number': phoneNumber,
      'email': email,
      'date_of_birth': dateOfBirth.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'address': address,
      'emergency_contact': emergencyContact,
      'emergency_phone': emergencyPhone,
      'medical_history': medicalHistory,
      'allergies': allergies,
      'blood_type': bloodType,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  // Copy with method for updating patient data
  Patient copyWith({
    String? id,
    String? fullName,
    String? gender,
    String? phoneNumber,
    String? email,
    DateTime? dateOfBirth,
    DateTime? lastVisitDate,
    String? address,
    String? emergencyContact,
    String? emergencyPhone,
    String? medicalHistory,
    String? allergies,
    String? bloodType,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Patient(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      bloodType: bloodType ?? this.bloodType,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Calculate age from date of birth
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  // Get formatted last visit date
  String get formattedLastVisit {
    if (lastVisitDate == null) return 'لم يزر من قبل';
    final now = DateTime.now();
    final difference = now.difference(lastVisitDate!);
    
    if (difference.inDays == 0) return 'اليوم';
    if (difference.inDays == 1) return 'أمس';
    if (difference.inDays < 7) return 'منذ ${difference.inDays} أيام';
    if (difference.inDays < 30) return 'منذ ${(difference.inDays / 7).floor()} أسابيع';
    if (difference.inDays < 365) return 'منذ ${(difference.inDays / 30).floor()} شهور';
    return 'منذ ${(difference.inDays / 365).floor()} سنوات';
  }

  // Get formatted gender in Arabic
  String get formattedGender {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'ذكر';
      case 'female':
        return 'أنثى';
      default:
        return 'غير محدد';
    }
  }

  // Get formatted date of birth
  String get formattedDateOfBirth {
    return '${dateOfBirth.day}/${dateOfBirth.month}/${dateOfBirth.year}';
  }

  // Check if patient has emergency contact
  bool get hasEmergencyContact {
    return emergencyContact.isNotEmpty;
  }

  // Check if patient has medical history
  bool get hasMedicalHistory {
    return medicalHistory.isNotEmpty;
  }

  // Check if patient has allergies
  bool get hasAllergies {
    return allergies.isNotEmpty;
  }

  // Get display name with title
  String get displayName {
    final title = gender.toLowerCase() == 'male' ? 'السيد' : 'السيدة';
    return '$title $fullName';
  }

  // Validate patient data
  List<String> validate() {
    List<String> errors = [];
    
    if (fullName.trim().isEmpty) {
      errors.add('الاسم الكامل مطلوب');
    }
    
    if (phoneNumber.trim().isEmpty) {
      errors.add('رقم الهاتف مطلوب');
    } else if (phoneNumber.length < 10) {
      errors.add('رقم الهاتف غير صحيح');
    }
    
    if (email.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      errors.add('البريد الإلكتروني غير صحيح');
    }
    
    if (gender.isEmpty || !['male', 'female'].contains(gender.toLowerCase())) {
      errors.add('الجنس مطلوب');
    }
    
    final age = this.age;
    if (age < 0 || age > 150) {
      errors.add('تاريخ الميلاد غير صحيح');
    }
    
    return errors;
  }

  // Check if patient data is valid
  bool get isValid {
    return validate().isEmpty;
  }

  @override
  String toString() {
    return 'Patient(id: $id, fullName: $fullName, gender: $gender, phoneNumber: $phoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Patient && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
