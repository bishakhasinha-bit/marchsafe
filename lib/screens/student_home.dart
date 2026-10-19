import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/data_service.dart';
import '../models/models.dart';
import '../theme.dart';
import '../shared/widgets.dart';
import 'package:intl/intl.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  User? _currentUser;
  Section? _userSection;
  Rehearsal? _currentRehearsal;
  List<CheckIn> _myCheckIns = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // In a real app we'd get current user from auth state
      _currentUser = dataService.currentUser ?? await dataService.getUser('student_8'); // Fallback to student_8 if no user
      
      if (_currentUser?.sectionId != null) {
        final sections = await dataService.getSections();
        _userSection = sections.firstWhere((s) => s.sectionId == _currentUser!.sectionId);
      }
      
      _currentRehearsal = await dataService.getCurrentRehearsal();
      
      final allCheckIns = await dataService.getAllCheckIns();
      _myCheckIns = allCheckIns.where((c) => c.userId == _currentUser?.userId).toList();
      _myCheckIns.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e, st) {
      debugPrint('Error loading student home data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MarchSafe'),
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
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.go('/'),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: context.textStyles.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MarchSafe'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hi, ${_currentUser?.firstName ?? 'Student'}',
              style: context.textStyles.displaySmall?.bold,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Status Card
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context, 
                      Icons.event, 
                      'Today\'s Rehearsal', 
                      _currentRehearsal != null 
                          ? DateFormat('MMMM d, yyyy').format(_currentRehearsal!.date)
                          : 'No Active Rehearsal'
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildInfoRow(
                      context, 
                      Icons.groups, 
                      'Band Section', 
                      _userSection?.name ?? 'Unassigned'
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildInfoRow(
                      context, 
                      Icons.check_circle_outline, 
                      'Check-In Status', 
                      'Pending' // In a real app we'd check if they checked in today
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            ActionCard(
              title: 'CHECK IN',
              subtitle: 'Tell us how you are feeling',
              icon: Icons.assignment_turned_in,
              iconColor: theme.colorScheme.primary,
              onTap: () => context.push('/student/check-in'),
            ),
            
            ActionCard(
              title: 'I NEED HELP',
              subtitle: 'Request immediate assistance',
              icon: Icons.emergency,
              iconColor: theme.colorScheme.error,
              onTap: () => context.push('/student/help'),
            ),
            
            ActionCard(
              title: 'MY TRIP PASS',
              subtitle: 'View your QR pass for active trips',
              icon: Icons.qr_code,
              iconColor: Colors.deepPurple,
              onTap: () => context.push('/student/trip-pass'),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Band Wellness Journey',
              style: context.textStyles.headlineSmall?.bold,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your self-reported ratings and concerns over time. Please note this is not a medical assessment.',
              style: context.textStyles.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_myCheckIns.isEmpty)
              const Text('No records available.')
            else ...[
              _buildWellnessChart(theme),
              const SizedBox(height: AppSpacing.lg),
              Text('Recent Reports', style: context.textStyles.titleMedium?.bold),
              const SizedBox(height: AppSpacing.sm),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _myCheckIns.length,
                itemBuilder: (context, index) {
                  final c = _myCheckIns[index];
                  return Card(
                    child: ListTile(
                      title: Text(DateFormat('MMMM d, yyyy').format(c.timestamp)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Concerns: ${c.concerns.join(', ')}'),
                          if (c.rehearsalComfort != null)
                            Text('Rehearsal Comfort: ${c.rehearsalComfort}/5'),
                          if (c.confidenceManagingDemands != null)
                            Text('Confidence: ${c.confidenceManagingDemands}/5'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            
            Text(
              'MarchSafe helps you communicate how you\'re feeling to responsible band staff.',
              textAlign: TextAlign.center,
              style: context.textStyles.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.textStyles.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: context.textStyles.titleMedium?.bold,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWellnessChart(ThemeData theme) {
    // Sort checkins chronologically for the chart
    final chartData = List<CheckIn>.from(_myCheckIns)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
    final validData = chartData.where((c) => c.rehearsalComfort != null && c.confidenceManagingDemands != null).toList();
    if (validData.isEmpty) return const SizedBox.shrink();

    final comfortSpots = <FlSpot>[];
    final confidenceSpots = <FlSpot>[];
    
    for (int i = 0; i < validData.length; i++) {
      comfortSpots.add(FlSpot(i.toDouble(), validData[i].rehearsalComfort!.toDouble()));
      confidenceSpots.add(FlSpot(i.toDouble(), validData[i].confidenceManagingDemands!.toDouble()));
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Comfort', Colors.blue),
                const SizedBox(width: 16),
                _buildLegendItem('Confidence', Colors.green),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 5,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < validData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('M/d').format(validData[idx].timestamp),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: comfortSpots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: confidenceSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
