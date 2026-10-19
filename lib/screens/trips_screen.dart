import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../theme.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  bool _isLoading = true;
  List<Trip> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    _trips = await dataService.getActiveTrips();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TripGuard'),
            Text(
              'Demo Mode',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade200,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: AppSpacing.paddingLg,
              itemCount: _trips.length,
              itemBuilder: (context, index) {
                final trip = _trips[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ListTile(
                    contentPadding: AppSpacing.paddingLg,
                    leading: const CircleAvatar(
                      child: Icon(Icons.directions_bus),
                    ),
                    title: Text(trip.name, style: context.textStyles.titleMedium?.bold),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xs),
                        Text('Destination: ${trip.destination}'),
                        Text('Departure: ${DateFormat('h:mm a').format(trip.departureTime)}'),
                        Text('Status: ${trip.status}', style: TextStyle(color: Theme.of(context).primaryColor)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    isThreeLine: true,
                    onTap: () {
                      context.push('/trip/${trip.tripId}');
                    },
                  ),
                );
              },
            ),
    );
  }
}
