import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/data_service.dart';
import '../models/models.dart';
import '../theme.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Section> _sections = [];
  List<CheckIn> _checkIns = [];
  List<CheckIn> _allCheckIns = [];
  List<Rehearsal> _rehearsals = [];
  List<HelpRequest> _helpRequests = [];
  List<Alert> _alerts = [];
  
  // Computed values
  int _totalCheckIns = 0;
  int _wellnessConcerns = 0;

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
      _sections = await dataService.getSections();
      _checkIns = await dataService.getTodayCheckIns();
      _allCheckIns = await dataService.getAllCheckIns();
      _rehearsals = await dataService.getRehearsals();
      _helpRequests = await dataService.getActiveHelpRequests();
      _alerts = await dataService.getActiveAlerts();
      
      // Calculate summaries
      _totalCheckIns = _checkIns.length;
      _wellnessConcerns = _checkIns.where(
        (c) => c.concerns.any((concern) => concern != 'Feeling Good')
      ).length;
    } catch (e, st) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getSectionName(String sectionId) {
    try {
      return _sections.firstWhere((s) => s.sectionId == sectionId).name;
    } catch (e) {
      return 'Unknown Section';
    }
  }

  Future<void> _updateRequestStatus(String requestId, String status, {String? note}) async {
    final staffId = dataService.currentUser?.userId ?? 'staff_1';
    await dataService.updateHelpRequestStatus(requestId, status, staffId, note: note);
    _loadData();
  }

  void _showResolutionDialog(String requestId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Resolve Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Assistance Provided'),
                onTap: () {
                  Navigator.pop(context);
                  _updateRequestStatus(requestId, 'Resolved', note: 'Assistance Provided');
                },
              ),
              ListTile(
                title: const Text('Referred to Medical Personnel'),
                onTap: () {
                  Navigator.pop(context);
                  _updateRequestStatus(requestId, 'Resolved', note: 'Referred to School Medical Personnel');
                },
              ),
              ListTile(
                title: const Text('Further Help Needed'),
                onTap: () {
                  Navigator.pop(context);
                  _updateRequestStatus(requestId, 'Resolved', note: 'Further Help Needed');
                },
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('MarchSafe Staff'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('MarchSafe Staff'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'MarchSafe Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_bus),
              title: const Text('TripGuard'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                context.push('/trips');
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Staff Dashboard'),
                  Text(
                    'Demo Mode — Fictional Student Data',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade200,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Summary Cards Grid
              GridView.extent(
                maxCrossAxisExtent: 160,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.2,
                children: [
                  _buildSummaryCard('Students Checked In', _totalCheckIns.toString(), Colors.blue),
                  _buildSummaryCard('Wellness Concerns', _wellnessConcerns.toString(), Colors.orange),
                  _buildSummaryCard('Help Requests', _helpRequests.length.toString(), Colors.red),
                  _buildSummaryCard('Emerging Patterns', _alerts.length.toString(), Colors.purple),
                ],
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Help Requests Section
              if (_helpRequests.isNotEmpty) ...[
                Text('Help Requests', style: context.textStyles.headlineSmall?.bold),
                const SizedBox(height: AppSpacing.md),
                ..._helpRequests.map(_buildHelpRequestCard),
                const SizedBox(height: AppSpacing.xl),
              ],
              
              // EarlySignal Panel
              if (_alerts.isNotEmpty || _rehearsals.isNotEmpty) ...[
                Text('EarlySignal: Pattern Detection', style: context.textStyles.headlineSmall?.bold),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Review recurring concerns across rehearsals and sections. '
                  'Thresholds configured for demonstration purposes. '
                  'Not a substitute for emergency response.',
                  style: context.textStyles.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildEarlySignalPanel(),
                const SizedBox(height: AppSpacing.xl),
              ],
              
              // Wellness Reports Section
              Text('Today\'s Wellness Reports', style: context.textStyles.headlineSmall?.bold),
              const SizedBox(height: AppSpacing.md),
              _buildWellnessReports(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, MaterialColor color) {
    return Card(
      color: color.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: color.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: context.textStyles.headlineMedium?.bold.copyWith(color: color.shade700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: context.textStyles.labelSmall?.copyWith(
                color: color.shade900,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpRequestCard(HelpRequest request) {
    final theme = Theme.of(context);
    final timeFormatted = DateFormat('h:mm a').format(request.timestamp);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: theme.colorScheme.error),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Student Help Request',
                  style: context.textStyles.titleLarge?.bold.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status,
                    style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDetailRow('Section', _getSectionName(request.sectionId)),
            _buildDetailRow('Concern', request.concern),
            _buildDetailRow('Time', timeFormatted),
            
            // Audit History
            if (request.auditHistory.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Audit History:', style: context.textStyles.labelMedium?.bold),
              ...request.auditHistory.map((audit) {
                return Text(
                  '- ${DateFormat('h:mm a').format(audit.timestamp)}: ${audit.status}${audit.note != null ? ' (${audit.note})' : ''}',
                  style: context.textStyles.bodySmall,
                );
              }),
            ],
            
            const SizedBox(height: AppSpacing.lg),
            if (request.status == 'Pending')
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: () => _updateRequestStatus(request.requestId, 'Acknowledged'),
                child: const Text('ACKNOWLEDGE'),
              )
            else if (request.status == 'Acknowledged')
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: () => _updateRequestStatus(request.requestId, 'In-Person Contact Confirmed'),
                child: const Text('CONFIRM IN-PERSON CONTACT'),
              )
            else if (request.status == 'In-Person Contact Confirmed')
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: () => _showResolutionDialog(request.requestId),
                child: const Text('RESOLVE REQUEST'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarlySignalPanel() {
    return DefaultTabController(
      length: 3,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            TabBar(
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: 'Individual'),
                Tab(text: 'Sections'),
                Tab(text: 'Trends'),
              ],
            ),
            SizedBox(
              height: 400,
              child: TabBarView(
                children: [
                  _buildIndividualPatternsTab(),
                  _buildSectionPatternsTab(),
                  _buildRehearsalTrendsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualPatternsTab() {
    final individualAlerts = _alerts.where((a) => a.type == 'individual').toList();
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: _buildTestDetectionControl(),
        ),
        if (individualAlerts.isEmpty)
          const Expanded(child: Center(child: Text('No recurring individual concerns detected.')))
        else
          Expanded(
            child: ListView.builder(
              padding: AppSpacing.paddingMd,
              itemCount: individualAlerts.length,
              itemBuilder: (context, index) {
                final alert = individualAlerts[index];
                return Column(
                  children: [
                    if (alert.concern == 'Dizzy / Lightheaded')
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          'Detection Source: Calculated from 3 fictional check-ins',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ),
                    _buildAlertCard(alert),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTestDetectionControl() {
    final checkIns = dataService.demoTestCheckIns;
    final isAlertActive = _alerts.any((a) => a.type == 'individual' && a.concern == 'Dizzy / Lightheaded');
    
    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.blue.shade700),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Demonstration Testing Control',
                    style: context.textStyles.titleMedium?.bold.copyWith(color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Test the EarlySignal pattern detection by temporarily removing one of a fictional student\'s wellness reports from the in-memory dataset.',
              style: context.textStyles.bodySmall?.copyWith(color: Colors.blue.shade800),
            ),
            const SizedBox(height: AppSpacing.md),
            ...checkIns.map((checkIn) {
              final isTarget = checkIn.rehearsalId == 'reh_oct14';
              final isRemoved = isTarget && !dataService.isDemoTestActive;
              
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isRemoved ? Colors.grey.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: isRemoved ? Colors.grey.shade300 : Colors.blue.shade100),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 0),
                  leading: Icon(
                    isRemoved ? Icons.event_busy : Icons.event_available,
                    color: isRemoved ? Colors.grey : Colors.green,
                  ),
                  title: Text(
                    'Rehearsal: ${DateFormat('MMM d').format(checkIn.timestamp)}',
                    style: TextStyle(
                      decoration: isRemoved ? TextDecoration.lineThrough : null,
                      color: isRemoved ? Colors.grey : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Concern: ${checkIn.concerns.join(', ')}',
                    style: TextStyle(
                      decoration: isRemoved ? TextDecoration.lineThrough : null,
                      color: isRemoved ? Colors.grey : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  trailing: isTarget ? TextButton.icon(
                    onPressed: () async {
                      await dataService.toggleDemoTest();
                      _loadData();
                    },
                    icon: Icon(
                      isRemoved ? Icons.restore : Icons.remove_circle_outline,
                      size: 16,
                      color: isRemoved ? Colors.blue : Colors.red,
                    ),
                    label: Text(isRemoved ? 'Restore' : 'Remove', style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: isRemoved ? Colors.blue : Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ) : const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Text('Required', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isAlertActive ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: isAlertActive ? Colors.red.shade200 : Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    isAlertActive ? Icons.warning : Icons.check_circle,
                    color: isAlertActive ? Colors.red : Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      isAlertActive 
                          ? 'Alert Active: 3 qualifying reports found within 14 days.' 
                          : 'Alert Cleared: Only 2 qualifying reports remain.',
                      style: context.textStyles.labelSmall?.bold.copyWith(
                        color: isAlertActive ? Colors.red.shade900 : Colors.green.shade900,
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

  Widget _buildSectionPatternsTab() {
    final sectionAlerts = _alerts.where((a) => a.type == 'section').toList();
    if (sectionAlerts.isEmpty) {
      return const Center(child: Text('No section-level patterns detected.'));
    }
    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: sectionAlerts.length,
      itemBuilder: (context, index) => _buildAlertCard(sectionAlerts[index]),
    );
  }

  Widget _buildRehearsalTrendsTab() {
    if (_rehearsals.isEmpty || _allCheckIns.isEmpty) {
      return const Center(child: Text('Not enough data for trends.'));
    }

    // Prepare chart data
    final rehearsalData = <DateTime, int>{};
    for (var r in _rehearsals) {
      rehearsalData[r.date] = 0; // Initialize
    }

    for (var c in _allCheckIns) {
      if (c.concerns.any((concern) => concern != 'Feeling Good')) {
        final r = _rehearsals.firstWhere((reh) => reh.rehearsalId == c.rehearsalId, orElse: () => Rehearsal(rehearsalId: '', date: DateTime(2000), status: ''));
        if (r.rehearsalId.isNotEmpty) {
          rehearsalData[r.date] = (rehearsalData[r.date] ?? 0) + 1;
        }
      }
    }

    final sortedDates = rehearsalData.keys.toList()..sort();
    final barGroups = <BarChartGroupData>[];
    int x = 0;
    for (var date in sortedDates) {
      barGroups.add(
        BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(
              toY: rehearsalData[date]!.toDouble(),
              color: Colors.purple.shade400,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            )
          ],
        )
      );
      x++;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('Concerns Over Time', style: context.textStyles.titleMedium?.bold),
          ),
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('M/d').format(sortedDates[value.toInt()]),
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
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value % 2 == 0) {
                            return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('Positive Trends', style: context.textStyles.titleMedium?.bold.copyWith(color: Colors.green.shade700)),
          ),
          ListTile(
            leading: Icon(Icons.trending_down, color: Colors.green.shade600),
            title: const Text('Fewer fatigue reports in the Woodwind section compared to last week.'),
            dense: true,
          ),
          ListTile(
            leading: Icon(Icons.trending_up, color: Colors.green.shade600),
            title: const Text('New members reporting higher rehearsal comfort ratings.'),
            dense: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Text(
              'Note: These trends are derived from student self-reports and do not constitute a medical outcome.',
              style: context.textStyles.labelSmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  void _showPatternReviewDialog(Alert alert) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Review Pattern'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Acknowledge review of this pattern. Provide an optional nonclinical follow-up note.'),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Follow-up Note (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final staffId = dataService.currentUser?.userId ?? 'staff_1';
                await dataService.reviewAlert(alert.alertId, staffId, noteController.text.trim().isEmpty ? 'Acknowledged' : noteController.text.trim());
                _loadData();
              },
              child: const Text('Acknowledge'),
            ),
          ],
        );
      }
    );
  }

  Widget _buildAlertCard(Alert alert) {
    final theme = Theme.of(context);
    final isReviewed = alert.status == 'reviewed';
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: isReviewed ? Colors.grey.shade50 : Colors.purple.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: isReviewed ? Colors.grey.shade300 : Colors.purple.shade200),
      ),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  alert.type == 'individual' ? Icons.person_search : Icons.groups,
                  color: isReviewed ? Colors.grey.shade600 : Colors.purple.shade700,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    alert.type == 'individual' 
                      ? 'Recurring Individual Concern'
                      : 'Section Pattern: ${_getSectionName(alert.sectionId)}',
                    style: context.textStyles.titleMedium?.bold.copyWith(
                      color: isReviewed ? Colors.grey.shade800 : Colors.purple.shade900,
                    ),
                  ),
                ),
                if (isReviewed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('REVIEWED', style: TextStyle(color: Colors.grey.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (alert.type == 'individual') ...[
              Text(
                'Student has reported "${alert.concern}" during ${alert.reportCount} rehearsals in the past 14 days.',
                style: context.textStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Rule: 3+ reports of the same concern by a single student within 14 days.',
                style: context.textStyles.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
              if (alert.rehearsalDates.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Dates: ${alert.rehearsalDates.map((d) => DateFormat('MMM d').format(d)).join(', ')}',
                  style: context.textStyles.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ] else ...[
              Text(
                '${alert.reportCount} students reported ${alert.concern} during today\'s rehearsal.',
                style: context.textStyles.bodyMedium,
              ),
            ],
            
            if (alert.reviews.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              Text('Review History', style: context.textStyles.labelSmall?.bold),
              ...alert.reviews.map((r) => Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${DateFormat('MMM d, h:mm a').format(r.timestamp)}: ${r.note ?? "Acknowledged"}',
                  style: context.textStyles.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              )),
            ],

            const SizedBox(height: AppSpacing.md),
            if (!isReviewed)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _showPatternReviewDialog(alert),
                    child: const Text('Review Pattern'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: context.textStyles.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: context.textStyles.bodyMedium?.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWellnessReports() {
    // Group by concern, then by section
    final Map<String, Map<String, int>> reports = {};
    
    for (var checkIn in _checkIns) {
      for (var concern in checkIn.concerns) {
        if (concern == 'Feeling Good') continue;
        
        if (!reports.containsKey(concern)) {
          reports[concern] = {};
        }
        
        reports[concern]![checkIn.sectionId] = (reports[concern]![checkIn.sectionId] ?? 0) + 1;
      }
    }
    
    if (reports.isEmpty) {
      return Card(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Center(
            child: Text(
              'No wellness concerns reported today.',
              style: context.textStyles.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: reports.entries.map((concernEntry) {
        final concern = concernEntry.key;
        final sectionCounts = concernEntry.value;
        
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Padding(
            padding: AppSpacing.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    concern,
                    style: context.textStyles.titleMedium?.bold,
                  ),
                ),
                const Divider(),
                ...sectionCounts.entries.map((sectionEntry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getSectionName(sectionEntry.key),
                          style: context.textStyles.bodyMedium,
                        ),
                        Text(
                          '${sectionEntry.value} reports',
                          style: context.textStyles.bodyMedium?.bold,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
