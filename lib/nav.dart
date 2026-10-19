import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/student_home.dart';
import 'screens/check_in_screen.dart';
import 'screens/help_screen.dart';
import 'screens/staff_dashboard.dart';
import 'screens/trips_screen.dart';
import 'screens/trip_details_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/student_trip_pass_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.studentHome,
        name: 'student_home',
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentCheckIn,
        name: 'student_check_in',
        builder: (context, state) => const CheckInScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentHelp,
        name: 'student_help',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentTripPass,
        name: 'student_trip_pass',
        builder: (context, state) => const StudentTripPassScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffDashboard,
        name: 'staff_dashboard',
        builder: (context, state) => const StaffDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffTrips,
        name: 'staff_trips',
        builder: (context, state) => const TripsScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffTripDetails,
        name: 'staff_trip_details',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return TripDetailsScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.staffTripScan,
        name: 'staff_trip_scan',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return ScanScreen(tripId: tripId);
        },
      ),
    ],
  );
}

class AppRoutes {
  static const String home = '/';
  static const String studentHome = '/student';
  static const String studentCheckIn = '/student/check-in';
  static const String studentHelp = '/student/help';
  static const String studentTripPass = '/student/trip-pass';
  static const String staffDashboard = '/staff';
  static const String staffTrips = '/trips';
  static const String staffTripDetails = '/trip/:tripId';
  static const String staffTripScan = '/trip/:tripId/scan';
}
