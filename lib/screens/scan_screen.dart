import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../theme.dart';

class ScanScreen extends StatefulWidget {
  final String tripId;
  const ScanScreen({super.key, required this.tripId});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isLoading = false;
  String? _selectedUserId;

  Future<void> _simulateScan() async {
    if (_selectedUserId == null) return;
    setState(() => _isLoading = true);

    final staffId = dataService.currentUser?.userId ?? 'staff_1';
    final currentBus = 'Bus 1'; // Assume staff is scanning for Bus 1 for this simulation
    
    final student = await dataService.getTripStudentByUser(widget.tripId, _selectedUserId!);
    
    if (student != null) {
      final event = ScanEvent(
        scanId: const Uuid().v4(),
        tripId: widget.tripId,
        userId: student.userId,
        scannedByStaffId: staffId,
        scannedBusId: currentBus,
        expectedBusId: student.busId,
        timestamp: DateTime.now(),
        checkpoint: 'Boarding',
      );
      
      await dataService.recordScanEvent(event);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentBus == student.busId 
              ? 'Scan successful for ${student.userId}' 
              : 'Wrong bus! ${student.userId} expected on ${student.busId}'),
            backgroundColor: currentBus == student.busId ? Colors.green : Colors.orange,
          )
        );
        context.pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR Token for this trip!'), backgroundColor: Colors.red),
        );
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulate QR Scan')),
      body: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.qr_code_scanner, size: 100, color: Colors.grey),
            const SizedBox(height: AppSpacing.xl),
            const Text('For demo purposes, select a student to simulate scanning their QR code on Bus 1:', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            DropdownButton<String>(
              value: _selectedUserId,
              hint: const Text('Select Student'),
              isExpanded: true,
              items: [
                'student_1', // On Bus 1
                'student_2', // On Bus 1
                'student_3', // On Bus 2 (will cause conflict if we scan again, or wrong bus if first scan)
                'student_4', // On Bus 2
                'invalid_student' // To test invalid
              ].map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(),
              onChanged: (val) => setState(() => _selectedUserId = val),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: _isLoading || _selectedUserId == null ? null : _simulateScan,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SIMULATE SCAN'),
            )
          ],
        ),
      ),
    );
  }
}
