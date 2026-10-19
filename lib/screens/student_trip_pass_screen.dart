import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../theme.dart';

class StudentTripPassScreen extends StatefulWidget {
  const StudentTripPassScreen({super.key});

  @override
  State<StudentTripPassScreen> createState() => _StudentTripPassScreenState();
}

class _StudentTripPassScreenState extends State<StudentTripPassScreen> {
  bool _isLoading = true;
  List<Trip> _activeTrips = [];
  Map<String, TripStudent> _tripAssignments = {};
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _currentUser = dataService.currentUser ?? await dataService.getUser('student_1');
    if (_currentUser != null) {
      final allTrips = await dataService.getActiveTrips();
      for (var trip in allTrips) {
        final assignment = await dataService.getTripStudentByUser(trip.tripId, _currentUser!.userId);
        if (assignment != null) {
          _activeTrips.add(trip);
          _tripAssignments[trip.tripId] = assignment;
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('My Trip Pass')),
      body: _activeTrips.isEmpty
          ? Center(
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Text('No active trips assigned.', style: context.textStyles.titleLarge),
              ),
            )
          : ListView.builder(
              padding: AppSpacing.paddingLg,
              itemCount: _activeTrips.length,
              itemBuilder: (context, index) {
                final trip = _activeTrips[index];
                final assignment = _tripAssignments[trip.tripId]!;
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: AppSpacing.paddingXl,
                    child: Column(
                      children: [
                        Text(trip.name, style: context.textStyles.headlineSmall?.bold),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Student: ${_currentUser?.firstName}', style: context.textStyles.titleMedium),
                        Text('Assigned Bus: ${assignment.busId}', style: context.textStyles.titleMedium?.copyWith(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: QrImageView(
                            data: assignment.qrToken,
                            version: QrVersions.auto,
                            size: 200.0,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text('Present this code to your chaperone.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
