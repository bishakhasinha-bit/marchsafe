import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../theme.dart';

class TripDetailsScreen extends StatefulWidget {
  final String tripId;
  const TripDetailsScreen({super.key, required this.tripId});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  bool _isLoading = true;
  Trip? _trip;
  List<TripStudent> _students = [];
  List<ScanEvent> _scans = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _trip = await dataService.getTrip(widget.tripId);
    if (_trip != null) {
      _students = await dataService.getTripStudents(widget.tripId);
      _scans = await dataService.getTripScans(widget.tripId);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _closeTrip() async {
    await dataService.closeTrip(widget.tripId);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_trip == null) {
      return const Scaffold(body: Center(child: Text('Trip not found')));
    }

    final totalAssigned = _students.length;
    // For simplicity, we just count unique student IDs in scans that are NOT conflicts or have been resolved
    final validScans = _scans.where((s) => !s.isConflict).toList();
    final uniqueScannedStudents = validScans.map((s) => s.userId).toSet().length;
    final missingCount = totalAssigned - uniqueScannedStudents;

    final conflicts = _scans.where((s) => s.isConflict).toList();
    final wrongBusScans = _scans.where((s) => !s.isConflict && s.scannedBusId != s.expectedBusId).toList();

    final canClearForDeparture = missingCount == 0 && conflicts.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_trip!.name),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Departure Clearance', style: context.textStyles.headlineSmall?.bold),
            const SizedBox(height: AppSpacing.md),
            _buildStatCard('Assigned Students', totalAssigned.toString(), Colors.blue),
            _buildStatCard('Verified Headcount', uniqueScannedStudents.toString(), Colors.green),
            if (missingCount > 0)
              _buildStatCard('Missing Students', missingCount.toString(), Colors.red),
            if (wrongBusScans.isNotEmpty)
              _buildStatCard('Wrong Bus Scans', wrongBusScans.length.toString(), Colors.orange),
            
            const SizedBox(height: AppSpacing.xl),
            
            if (conflicts.isNotEmpty) ...[
              Text('Location Conflicts (${conflicts.length})', style: context.textStyles.titleLarge?.bold.copyWith(color: Colors.red)),
              const SizedBox(height: AppSpacing.sm),
              ...conflicts.map(_buildConflictCard),
              const SizedBox(height: AppSpacing.xl),
            ],

            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('SCAN QR CODE'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await context.push('/trip/${widget.tripId}/scan');
                _loadData();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: canClearForDeparture ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
              ),
              onPressed: canClearForDeparture ? _closeTrip : null,
              child: Text(canClearForDeparture ? 'APPROVE DEPARTURE & CLOSE TRIP' : 'CANNOT DEPART YET'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: color.withValues(alpha: 0.1),
      child: ListTile(
        title: Text(label, style: context.textStyles.titleMedium),
        trailing: Text(value, style: context.textStyles.headlineSmall?.bold.copyWith(color: color)),
      ),
    );
  }

  Widget _buildConflictCard(ScanEvent scan) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: Colors.red.shade50,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student ID: ${scan.userId}', style: context.textStyles.titleMedium?.bold),
            Text('Scanned on ${scan.scannedBusId} by ${scan.scannedByStaffId}'),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: () => _showResolveDialog(scan.scanId),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('VERIFY PHYSICAL LOCATION'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResolveDialog(String scanId) {
    String note = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verify Location'),
          content: TextField(
            decoration: const InputDecoration(labelText: 'Verification Note'),
            onChanged: (v) => note = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final staffId = dataService.currentUser?.userId ?? 'staff_1';
                await dataService.resolveScanConflict(scanId, staffId, note);
                _loadData();
              },
              child: const Text('RESOLVE'),
            ),
          ],
        );
      }
    );
  }
}
