import 'package:dbs/features/auth/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';

import '../core/guards/auth_guard.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
// ignore: unused_import
import '../features/profile/presentation/pages/profile_setup_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../debug/auth_debug_page.dart';
import '../features/admin/presentation/pages/admin_dashboard.dart';
import '../features/admin/presentation/pages/users_list_page.dart';
import '../features/booking/presentation/pages/booking_flow_page.dart';
import '../features/booking/presentation/pages/booking_appointment_page.dart';
import '../features/booking/presentation/pages/appointment_page.dart';
import '../features/booking/presentation/pages/admin_appointments_page.dart';
import '../features/booking/presentation/pages/doctor_appointments_page.dart';
import '../features/booking/presentation/pages/patient_appointments_page.dart';
import '../features/doctor/presentation/pages/doctor_profile_page.dart';
import '../features/doctor/domain/entities/doctor.dart';
import '../features/schedule/presentation/pages/schedule_page.dart';

class Routes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const authRedirect = '/auth';
  static const home = '/home';
  static const admin = '/admin';
  static const adminUsers = '/admin/users';
  static const adminAppointments = '/admin/appointments';
  static const adminAllAppointments = '/admin/appointments/all';
  static const doctorAppointments = '/doctor/appointments';
  static const myAppointments = '/appointments';
  static const booking = '/booking';
  static const bookingAppointment = '/booking/appointment';
  static const doctorProfile = '/doctor/profile';
  static const schedule = '/schedule';
  static const authDebug = '/debug/auth';

  static final Map<String, WidgetBuilder> pages = {
    splash: (_) => const SplashPage(),
    login: (_) => LoginPage(),
    register: (_) => RegisterPage(),

    authRedirect: (_) => AuthGuard(
          unauthenticated: LoginPage(),
          authenticated: HomePage(),
        ),

    home: (_) => HomePage(),
    admin: (_) => const AdminDashboardPage(),
    adminUsers: (_) => const UsersListPage(),
  adminAppointments: (_) => const AppointmentPage(),
  adminAllAppointments: (_) => const AdminAppointmentsPage(),
    doctorAppointments: (context) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      final id = (arg is String) ? arg : '';
      return DoctorAppointmentsPage(doctorId: id);
    },
  myAppointments: (_) => const PatientAppointmentsPage(),
    booking: (_) => const BookingFlowPage(),
  bookingAppointment: (context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    final doctor = (arg is DoctorEntity) ? arg : null;
    return BookingAppointmentPage(initialDoctor: doctor);
  },
    doctorProfile: (_) => const DoctorProfilePage(),
    schedule: (_) => const SchedulePage(),
    authDebug: (_) => const AuthDebugPage(),
  };

  // static String? get splash => null;
}
