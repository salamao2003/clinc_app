// backend/patient_model.dart
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
  final String medicalHistory;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    this.medicalHistory = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor for creating Patient from JSON (Supabase format)
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
      medicalHistory: json['medical_history']?.toString() ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  // Convert Patient to JSON (Supabase format)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'gender': gender,
      'phone_number': phoneNumber,
      'email': email,
      'date_of_birth': dateOfBirth.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'last_visit_date': lastVisitDate?.toIso8601String(),
      'address': address,
      'emergency_contact': emergencyContact,
      'medical_history': medicalHistory,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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
    String? medicalHistory,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      medicalHistory: medicalHistory ?? this.medicalHistory,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (lastVisitDate == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(lastVisitDate!);
    
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} months ago';
    return '${(difference.inDays / 365).floor()} years ago';
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