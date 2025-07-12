import 'package:flutter/material.dart';
import '../backend/Appointments_logic.dart';
import '../widgets/app_sidebar.dart';
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _isArabic = false;

  // ألوان ثابتة
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  final AppointmentsLogic _logic = AppointmentsLogic();
  List<Appointment> _appointments = [];
  List<Appointment> _filteredAppointments = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  
  // Filter variables
  String? _selectedStatus;
  String? _selectedVisitType;
  String? _selectedDoctor;

  Future<void> _fetchAppointments() async {
    setState(() => _loading = true);
    _appointments = await _logic.fetchAppointments();
    _filteredAppointments = _appointments;
    
    // إعادة تطبيق البحث والفلاتر إذا كانت موجودة
    _applyFilters();
    
    setState(() => _loading = false);
  }

  void _filterAppointments(String query) {
    setState(() {
      _filteredAppointments = _appointments.where((appointment) {
        // Text search filter
        bool matchesSearch = true;
        if (query.isNotEmpty) {
          final patientName = appointment.patientName.toLowerCase();
          final phoneNumber = appointment.phoneNumber.toLowerCase();
          final searchQuery = query.toLowerCase();
          matchesSearch = patientName.contains(searchQuery) || phoneNumber.contains(searchQuery);
        }
        
        // Status filter
        bool matchesStatus = _selectedStatus == null || appointment.status == _selectedStatus;
        
        // Visit type filter
        bool matchesVisitType = _selectedVisitType == null || appointment.visitType == _selectedVisitType;
        
        // Doctor filter
        bool matchesDoctor = _selectedDoctor == null || appointment.doctorName == _selectedDoctor;
        
        return matchesSearch && matchesStatus && matchesVisitType && matchesDoctor;
      }).toList();
    });
  }

  void _applyFilters() {
    _filterAppointments(_searchController.text);
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedVisitType = null;
      _selectedDoctor = null;
      _searchController.clear();
    });
    _filterAppointments('');
  }

  List<String> _getUniqueStatuses() {
    return _appointments.map((a) => a.status).toSet().toList();
  }

  List<String> _getUniqueVisitTypes() {
    return _appointments.map((a) => a.visitType).toSet().toList();
  }

  List<String> _getUniqueDoctors() {
    return _appointments
        .where((a) => a.doctorName != null && a.doctorName!.isNotEmpty)
        .map((a) => a.doctorName!)
        .toSet()
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
    _searchController.addListener(() {
      setState(() {}); // لإعادة رسم الـ suffix icon
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Row(
          children: [
            // Sidebar
            AppSidebar(
                    parentContext: context,
                    selectedPage: 'appointments',
                    isArabic: _isArabic,
                  ),
            // Main Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Text(
                          _isArabic ? 'إدارة المواعيد' : 'Appointments Management',
                          style: const TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const Spacer(),
                        // زر تغيير اللغة
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isArabic = !_isArabic;
                            });
                          },
                          icon: const Icon(Icons.language, color: primaryBlue),
                          label: Text(_isArabic ? 'English' : 'عربي', style: const TextStyle(color: primaryBlue)),
                        ),
                        const SizedBox(width: 16),
                        // زر إضافة موعد جديد
                        ElevatedButton.icon(
                          onPressed: () {
                            _showAppointmentDialog();
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: Text(
                            _isArabic ? 'إضافة موعد جديد' : 'Add New Appointment',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search Bar and Filters
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _filterAppointments,
                            decoration: InputDecoration(
                              hintText: _isArabic ? 'البحث باسم المريض أو رقم التليفون...' : 'Search by patient name or phone number...',
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.grey),
                                      onPressed: () {
                                        _searchController.clear();
                                        _filterAppointments('');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Filters Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Status Filter
                              _buildFilterDropdown(
                                title: _isArabic ? 'الحالة' : 'Status',
                                value: _selectedStatus,
                                items: _getUniqueStatuses(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatus = value;
                                  });
                                  _applyFilters();
                                },
                                getDisplayText: (status) {
                                  if (_isArabic) {
                                    switch (status) {
                                      case 'Confirmed': return 'مؤكد';
                                      case 'Pending': return 'قيد الانتظار';
                                      case 'Cancelled': return 'ملغي';
                                      default: return status;
                                    }
                                  }
                                  return status;
                                },
                              ),
                              const SizedBox(width: 20),
                              // Visit Type Filter
                              _buildFilterDropdown(
                                title: _isArabic ? 'نوع الزيارة' : 'Visit Type',
                                value: _selectedVisitType,
                                items: _getUniqueVisitTypes(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedVisitType = value;
                                  });
                                  _applyFilters();
                                },
                                getDisplayText: (visitType) {
                                  if (_isArabic) {
                                    switch (visitType) {
                                      case 'checkup': return 'فحص';
                                      case 'follow up': return 'متابعة';
                                      case 'first visit': return 'زيارة أولى';
                                      default: return visitType;
                                    }
                                  }
                                  return visitType;
                                },
                              ),
                              const SizedBox(width: 20),
                              // Doctor Filter
                              _buildFilterDropdown(
                                title: _isArabic ? 'الطبيب' : 'Doctor',
                                value: _selectedDoctor,
                                items: _getUniqueDoctors(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDoctor = value;
                                  });
                                  _applyFilters();
                                },
                                getDisplayText: (doctor) => doctor,
                              ),
                              const SizedBox(width: 20),
                              // Clear Filters Button
                              if (_selectedStatus != null || _selectedVisitType != null || _selectedDoctor != null)
                                ElevatedButton.icon(
                                  onPressed: _clearFilters,
                                  icon: const Icon(Icons.clear, size: 16),
                                  label: Text(_isArabic ? 'مسح الفلاتر' : 'Clear Filters'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[100],
                                    foregroundColor: Colors.grey[700],
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Body Placeholder
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: _loading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(50),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : _filteredAppointments.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(50),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.search_off,
                                              size: 64,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              _searchController.text.isNotEmpty
                                                  ? (_isArabic ? 'لا توجد نتائج للبحث' : 'No search results found')
                                                  : (_isArabic ? 'لا توجد مواعيد' : 'No appointments found'),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 18,
                                              ),
                                            ),
                                            if (_searchController.text.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                _isArabic ? 'جرب البحث بكلمات مختلفة' : 'Try searching with different terms',
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: DataTable(
                                        columnSpacing: 24,
                                        headingRowColor: MaterialStateProperty.all(primaryBlue.withOpacity(0.08)),
                                        columns: [
                                          DataColumn(label: Text(_isArabic ? 'اسم المريض' : 'Patient Name')),
                                          DataColumn(label: Text(_isArabic ? 'رقم التليفون' : 'Phone Number')),
                                          DataColumn(label: Text(_isArabic ? 'اسم الدكتور' : 'Doctor Name')),
                                          DataColumn(label: Text(_isArabic ? 'التاريخ والوقت' : 'Date & Time')),
                                          DataColumn(label: Text(_isArabic ? 'نوع الزيارة' : 'Visit Type')),
                                          DataColumn(label: Text(_isArabic ? 'الحالة' : 'Status')),
                                          DataColumn(label: Text(_isArabic ? 'ملاحظات' : 'Notes')),
                                          DataColumn(label: Text(_isArabic ? 'الإجراءات' : 'Actions')),
                                        ],
                                        rows: _filteredAppointments.map((appointment) {
                                          return _buildAppointmentRow(
                                            patient: appointment.patientName,
                                            phone: appointment.phoneNumber,
                                            doctorName: appointment.doctorName ?? '',
                                            visitType: appointment.visitType,
                                            dateTime: "${appointment.appointmentDate.toLocal().toString().split(' ')[0]}, ${_formatTimeTo12Hour(appointment.appointmentTime)}",
                                            status: appointment.status,
                                            notes: appointment.notes ?? '',
                                            appointmentId: appointment.id,
                                          );
                                        }).toList(),
                                      ),
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

  DataRow _buildAppointmentRow({
    required String patient,
    required String phone,
    required String doctorName,
    required String visitType,
    required String dateTime,
    required String status,
    required String notes,
     required String appointmentId, // أضف هذا المعامل
  }) {
    Color statusColor;
    switch (status) {
      case 'Confirmed':
        statusColor = Colors.green;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }
    return DataRow(
      cells: [
        DataCell(Text(patient)),
        DataCell(Text(phone)),
         DataCell(Text(doctorName.isEmpty ? (_isArabic ? 'غير محدد' : 'Not specified') : doctorName)),
        DataCell(Text(dateTime)),
        DataCell(Text(visitType)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _isArabic
                  ? (status == 'Confirmed'
                      ? 'مؤكد'
                      : status == 'Pending'
                          ? 'قيد الانتظار'
                          : 'ملغي')
                  : status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
         DataCell(
        Container(
          width: 100,
          child: Text(
            notes.isEmpty ? (_isArabic ? 'لا توجد' : 'No notes') : notes,
            style: TextStyle(
              color: notes.isEmpty ? Colors.grey : Colors.black87,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ),
        DataCell(Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit,),
              tooltip: _isArabic ? 'تعديل' : 'Edit',
              onPressed: () {
              // البحث عن الموعد الحالي
              final appointment = _appointments.firstWhere(
                (app) => app.id == appointmentId,
              );
              
              // تحويل بيانات الموعد لـ Map
              final appointmentData = {
                'appointmentId': appointment.id,
                'patientName': appointment.patientName,
                'phoneNumber': appointment.phoneNumber,
                'visitType': appointment.visitType,
                'date': appointment.appointmentDate.toIso8601String().split('T')[0],
                'time': appointment.appointmentTime,
                'duration': appointment.durationMinutes,
                'status': appointment.status,
                'notes': appointment.notes ?? '',
                'doctor': appointment.doctorName ?? '',
              };
              
              // فتح نافذة التعديل
              _showAppointmentDialog(isEdit: true, data: appointmentData);
            },
            ),
            IconButton(
              icon: const Icon(Icons.delete,),
              tooltip: _isArabic ? 'حذف' : 'Delete',
             onPressed: () => _showDeleteConfirmation(appointmentId),
              color: Colors.red,
            ),
          ],
        )),
      ],
    );
  }

// أضف هذه الدالة في _AppointmentsScreenState:

Future<void> _showDeleteConfirmation(String appointmentId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(_isArabic ? 'تأكيد الحذف' : 'Confirm Delete'),
      content: Text(_isArabic ? 'هل أنت متأكد من حذف هذا الموعد؟' : 'Are you sure you want to delete this appointment?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(_isArabic ? 'حذف' : 'Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await _logic.deleteAppointment(appointmentId);
    await _fetchAppointments();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isArabic ? 'تم حذف الموعد بنجاح' : 'Appointment deleted successfully')),
      );
    }
  }
}

  Future<void> _showAppointmentDialog({bool isEdit = false, Map<String, dynamic>? data}) async {
    final scaffoldContext = context; // احفظ context الأصلي هنا
  
    final _formKey = GlobalKey<FormState>();
    String patientName = data?['patientName'] ?? '';
    String phoneNumber = data?['phoneNumber'] ?? '';
    String visitType = data?['visitType'] ?? '';
    DateTime? date = data?['date'] != null ? DateTime.parse(data!['date']) : null;
    TimeOfDay? time = data?['time'] != null ? TimeOfDay.fromDateTime(
      DateTime.parse('2023-01-01 ${data!['time']}')
    ) : null;
    int duration = data?['duration'] ?? 30;
    String doctor = data?['doctor'] ?? '';
    String status = data?['status'] ?? 'Pending';
    String notes = data?['notes'] ?? '';
    
    bool isPatientLoading = false;
    List<String> busyTimes = [];
    bool isTimeConflict = false;

    // دالة للتحقق من تضارب الأوقات
    Future<void> checkTimeConflict() async {
      if (date != null && time != null) {
        final timeString = '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}:00';
        isTimeConflict = busyTimes.contains(timeString);
      }
    }

    // دالة لتحديث المواعيد المشغولة عند تغيير التاريخ
    Future<void> updateBusyTimes() async {
      if (date != null) {
        busyTimes = await _logic.getBusyTimesForDate(date!);
        await checkTimeConflict();
      }
    }

    final TextEditingController _dateController = TextEditingController(
      text: data?['date'] ?? '',
    );
    final TextEditingController _timeController = TextEditingController(
      text: data?['time'] ?? '',
    );
    final TextEditingController _phoneController = TextEditingController(
      text: phoneNumber,
    );

    await showDialog(
      context: context,
      builder: (dialogContext) { // استخدم اسم مختلف للـ dialog context
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          isEdit
                              ? (_isArabic ? 'تعديل موعد' : 'Edit Appointment')
                              : (_isArabic ? 'إضافة موعد جديد' : 'Add New Appointment'),
                          style: const TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // رقم التليفون
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: _isArabic ? 'رقم التليفون' : 'Phone Number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: isPatientLoading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : null,
                        ),
                        validator: (v) => v == null || v.isEmpty ? (_isArabic ? 'مطلوب' : 'Required') : null,
                        keyboardType: TextInputType.phone,
                        onChanged: (value) async {
                          phoneNumber = value;
                          
                          if (value.length >= 10) {
                            setDialogState(() {
                              isPatientLoading = true;
                            });
                            
                            try {
                              final patient = await _logic.getPatientByPhone(value);
                              setDialogState(() {
                                if (patient != null) {
                                  patientName = patient.fullName;
                                } else {
                                  patientName = '';
                                }
                                isPatientLoading = false;
                              });
                            } catch (e) {
                              setDialogState(() {
                                patientName = '';
                                isPatientLoading = false;
                              });
                            }
                          } else {
                            setDialogState(() {
                              patientName = '';
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
                      
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: _isArabic ? 'التاريخ' : 'Date',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        validator: (v) => (date == null) ? (_isArabic ? 'مطلوب' : 'Required') : null,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            locale: _isArabic ? const Locale('ar') : const Locale('en'),
                          );
                          if (picked != null) {
                            date = picked;
                            _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            
                            // تحديث المواعيد المشغولة عند تغيير التاريخ
                            setDialogState(() {});
                            await updateBusyTimes();
                            setDialogState(() {});
                          }
                        },
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _timeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: _isArabic ? 'الوقت' : 'Time',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isTimeConflict ? Colors.red : Colors.grey.shade300,
                            width: isTimeConflict ? 2 : 1,
                          ),
                        ),
                        suffixIcon: isTimeConflict 
                          ? const Icon(Icons.warning, color: Colors.red)
                          : const Icon(Icons.access_time),
                      ),
                      validator: (v) => (time == null) ? (_isArabic ? 'مطلوب' : 'Required') : null,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          time = picked;
                          _timeController.text = picked.format(context);
                          
                          // التحقق من تضارب الأوقات عند تغيير الوقت
                          await checkTimeConflict();
                          setDialogState(() {});
                        }
                      },
                    ),
                    
                    // عرض تحذير في حالة تضارب الأوقات
                    if (isTimeConflict) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isArabic 
                                  ? 'تحذير: هذا الوقت محجوز بالفعل. سيتم رفض الحجز إذا كان الموعد السابق مؤكد أو في الانتظار.'
                                  : 'Warning: This time slot is already booked. The booking will be rejected if the previous appointment is confirmed or pending.',
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: duration.toString(),
                      decoration: InputDecoration(
                        labelText: _isArabic ? 'المدة (دقيقة)' : 'Duration (minutes)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => duration = int.tryParse(v) ?? 30,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: doctor,
                      decoration: InputDecoration(
                        labelText: _isArabic ? 'الطبيب (اختياري)' : 'Doctor (optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => doctor = v,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: visitType.isNotEmpty ? visitType : null,
                      items: const [
                        DropdownMenuItem(value: 'follow up', child: Text('Follow Up')),
                        DropdownMenuItem(value: 'first visit', child: Text('First Visit')),
                      ],
                      onChanged: (v) => visitType = v ?? '',
                      decoration: InputDecoration(
                        labelText: _isArabic ? 'نوع الزيارة' : 'Visit Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.isEmpty ? (_isArabic ? 'مطلوب' : 'Required') : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: status,
                      items: [
                        DropdownMenuItem(value: 'Confirmed', child: Text(_isArabic ? 'مؤكد' : 'Confirmed')),
                        DropdownMenuItem(value: 'Pending', child: Text(_isArabic ? 'قيد الانتظار' : 'Pending')),
                        DropdownMenuItem(value: 'Cancelled', child: Text(_isArabic ? 'ملغي' : 'Cancelled')),
                      ],
                      onChanged: (v) => status = v ?? 'Pending',
                      decoration: InputDecoration(
                        labelText: _isArabic ? 'الحالة' : 'Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: notes,
                      decoration: InputDecoration(
                        labelText: _isArabic ? 'ملاحظات (اختياري)' : 'Notes (optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 2,
                      onChanged: (v) => notes = v,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState?.validate() == true && date != null && time != null && patientName.isNotEmpty) {
                              final appointmentTime = time!.format(dialogContext);
                              
                              try {
                                if (isEdit) {
                                  // تعديل الموعد
                                  await _logic.updateAppointment(
                                    appointmentId: data!['appointmentId'],
                                    phoneNumber: phoneNumber,
                                    doctorName: doctor.isEmpty ? null : doctor,
                                    visitType: visitType,
                                    appointmentDate: date!,
                                    appointmentTime: appointmentTime,
                                    durationMinutes: duration,
                                    status: status,
                                    notes: notes,
                                  );
                                } else {
                                  // إضافة موعد جديد
                                  await _logic.addAppointment(
                                    phoneNumber: phoneNumber,
                                    doctorName: doctor.isEmpty ? null : doctor,
                                    visitType: visitType,
                                    appointmentDate: date!,
                                    appointmentTime: appointmentTime,
                                    durationMinutes: duration,
                                    status: status,
                                    notes: notes,
                                  );
                                }
                                
                                Navigator.pop(dialogContext); // استخدم dialogContext
                                await _fetchAppointments();
                                
                                // استخدم scaffoldContext بدلاً من context
                                if (mounted) {
                                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                    SnackBar(content: Text(isEdit 
                                      ? (_isArabic ? 'تم تحديث الموعد بنجاح' : 'Appointment updated successfully')
                                      : (_isArabic ? 'تم إضافة الموعد بنجاح' : 'Appointment added successfully')
                                    )),
                                  );
                                }
                              } catch (e) {
                                String errorMessage;
                                if (e.toString().contains('Appointment time already booked')) {
                                  // استخراج اسم المريض من رسالة الخطأ
                                  final match = RegExp(r'booked by (.+) \((.+)\)').firstMatch(e.toString());
                                  if (match != null) {
                                    final patientNameConflict = match.group(1);
                                    final statusConflict = match.group(2);
                                    errorMessage = _isArabic 
                                      ? 'هذا الموعد محجوز بالفعل للمريض: $patientNameConflict (الحالة: $statusConflict)'
                                      : 'This appointment time is already booked by: $patientNameConflict (Status: $statusConflict)';
                                  } else {
                                    errorMessage = _isArabic 
                                      ? 'هذا الموعد محجوز بالفعل' 
                                      : 'This appointment time is already booked';
                                  }
                                } else if (e.toString().contains('Patient not found')) {
                                  errorMessage = _isArabic 
                                    ? 'لم يتم العثور على مريض بهذا الرقم' 
                                    : 'Patient not found with this phone number';
                                } else {
                                  errorMessage = _isArabic 
                                    ? 'حدث خطأ أثناء حفظ الموعد' 
                                    : 'An error occurred while saving the appointment';
                                }
                                
                                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMessage),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            } else if (patientName.isEmpty) {
                              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                SnackBar(
                                  content: Text(_isArabic ? 'يرجى إدخال رقم تليفون صحيح للمريض' : 'Please enter a valid patient phone number'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          child: Text(
                            isEdit ? (_isArabic ? 'حفظ' : 'Save') : (_isArabic ? 'إضافة' : 'Add'),
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
          }
        );
      },
    );
  }

  String _formatTimeTo12Hour(String time24) {
    try {
      // تحويل النص إلى TimeOfDay
      final timeParts = time24.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      final timeOfDay = TimeOfDay(hour: hour, minute: minute);
      
      // تحويل إلى نظام 12 ساعة
      final hour12 = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
      final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
      final formattedMinute = minute.toString().padLeft(2, '0');
      
      return '$hour12:$formattedMinute $period';
    } catch (e) {
      // في حالة حدوث خطأ، إرجاع الوقت الأصلي
      return time24;
    }
  }

  Widget _buildFilterDropdown({
    required String title,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String Function(String) getDisplayText,
  }) {
    return Row(
      children: [
        Text(
          title + ':',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: value != null ? primaryBlue.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: value != null ? primaryBlue.withOpacity(0.3) : Colors.grey.shade300,
            ),
          ),
          child: DropdownButton<String>(
            hint: Text(
              _isArabic ? 'الكل' : 'All',
              style: TextStyle(
                fontSize: 12,
                color: value != null ? primaryBlue : Colors.grey[600],
                fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            value: value,
            underline: const SizedBox(),
            icon: Icon(
              Icons.arrow_drop_down,
              color: value != null ? primaryBlue : Colors.grey[600],
              size: 16,
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  _isArabic ? 'الكل' : 'All',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              ...items.map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  getDisplayText(item),
                  style: const TextStyle(fontSize: 12),
                ),
              )),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}