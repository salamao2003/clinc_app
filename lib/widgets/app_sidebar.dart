import 'package:flutter/material.dart';
import '../screens/patients_screen.dart';
import '../screens/Appointments_screen.dart';
import '../screens/prescription_screen.dart';
import '../screens/billing_screen.dart';
import '../screens/Reports_screen.dart';
import '../screens/settings_screen.dart';
// أضف باقي الصفحات هنا
import '../screens/login_screen.dart';
import '../screens/animated_page_transition.dart'; 
class AppSidebar extends StatelessWidget {
  final BuildContext parentContext;
  final String selectedPage; // مثال: 'patients', 'appointments', ...
  final bool isArabic;

  const AppSidebar({
    Key? key,
    required this.parentContext,
    required this.selectedPage,
    this.isArabic = false,
  }) : super(key: key);

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      selected: selected,
      selectedTileColor: Colors.blue.withOpacity(0.08),
      leading: Icon(icon, color: color ?? (selected ? Colors.blue : Colors.grey[700])),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? (selected ? Colors.blue : Colors.grey[800]),
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Colors.white,
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_hospital, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                Text(
                  isArabic ? 'نظام العيادة' : 'Insta Clinic',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: isArabic ? 'المرضى' : 'Patients',
            selected: selectedPage == 'patients',
            onTap: () {
              if (selectedPage != 'patients') {
                navigateWithAnimation(parentContext, const PatientsScreen());
              }
            },
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today,
            title: isArabic ? 'المواعيد' : 'Appointments',
            selected: selectedPage == 'appointments',
            onTap: () {
              if (selectedPage != 'appointments') {
                navigateWithAnimation(parentContext, const AppointmentsScreen());
              }
            },
          ),
          _buildDrawerItem(
            icon: Icons.medical_services,
            title: isArabic ? 'الوصفات الطبية' : 'Prescriptions',
            selected: selectedPage == 'prescriptions',
            onTap: () {
              if (selectedPage != 'prescriptions') {
                navigateWithAnimation(parentContext, const PrescriptionScreen());
              }
            },
          ),
          _buildDrawerItem(
            icon: Icons.receipt_long,
            title: isArabic ? 'الفواتير' : 'Billing',
            selected: selectedPage == 'billing',
            onTap: () {
              navigateWithAnimation(parentContext, BillingScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.analytics,
            title: isArabic ? 'التقارير' : 'Reports',
            selected: selectedPage == 'reports',
            onTap: () {
               navigateWithAnimation(parentContext, ReportsScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: isArabic ? 'الإعدادات' : 'Settings',
            selected: selectedPage == 'settings',
            onTap: () {
              navigateWithAnimation(parentContext, const SettingsScreen());
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: isArabic ? 'تسجيل الخروج' : 'Logout',
            selected: false,
            color: Colors.red,
            onTap: () {
              navigateWithAnimation(parentContext, const LoginScreen());
            },
          ),
        ],
      ),
    );
  }
}