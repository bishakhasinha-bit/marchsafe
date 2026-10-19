import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

abstract class DataService {
  Future<void> init();
  User? get currentUser;
  Future<User?> login(String username, String role);
  Future<List<Section>> getSections();
  Future<Rehearsal?> getCurrentRehearsal();
  Future<List<Rehearsal>> getRehearsals(); // New
  Future<User?> getUser(String userId);
  Future<void> submitCheckIn(CheckIn checkIn);
  Future<void> submitHelpRequest(HelpRequest request);
  Future<List<CheckIn>> getTodayCheckIns();
  Future<List<CheckIn>> getAllCheckIns(); // New
  Future<List<HelpRequest>> getActiveHelpRequests();
  Future<List<Alert>> getActiveAlerts();
  Future<void> acknowledgeHelpRequest(String requestId, String staffId);
  Future<void> updateHelpRequestStatus(String requestId, String status, String staffId, {String? note});
  Future<void> reviewAlert(String alertId, String staffId, String note); // New
  
  // TripGuard
  Future<List<Trip>> getActiveTrips();
  Future<Trip?> getTrip(String tripId);
  Future<void> createTrip(Trip trip);
  Future<void> closeTrip(String tripId);
  Future<List<TripStudent>> getTripStudents(String tripId);
  Future<TripStudent?> getTripStudentByUser(String tripId, String userId);
  Future<void> assignStudentToTrip(TripStudent student);
  Future<void> recordScanEvent(ScanEvent event);
  Future<List<ScanEvent>> getTripScans(String tripId);
  Future<void> resolveScanConflict(String scanId, String staffId, String note);
  Future<void> loadDemoScenario(int scenarioId);
  Future<void> toggleDemoTest();
  Future<void> setupDemoAccounts(); // New for Firebase Auth
  bool get isDemoTestActive;
  void updateExternalCheckIns(List<CheckIn> checkIns);
  List<CheckIn> get demoTestCheckIns;
  Future<void> resetDemoData(); // New
}

class InMemoryDataService implements DataService {
  final _uuid = const Uuid();
  
  // Data stores
  final List<User> _users = [];
  final List<Section> _sections = [];
  final List<Rehearsal> _rehearsals = [];
  final List<CheckIn> _checkIns = [];
  final List<HelpRequest> _helpRequests = [];
  final List<Alert> _alerts = [];
  
  // TripGuard data stores
  final List<Trip> _trips = [];
  final List<TripStudent> _tripStudents = [];
  final List<ScanEvent> _scanEvents = [];
  
  User? _currentUser;
  SharedPreferences? _prefs;
  
  @override
  User? get currentUser => _currentUser;
  
  InMemoryDataService();

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs!.getBool('demo_initialized') == true) {
      _loadFromPrefs();
    } else {
      _initializeDemoData();
      await _saveToPrefs();
      await _prefs!.setBool('demo_initialized', true);
    }
  }

  void _loadFromPrefs() {
    try {
      if (_prefs == null) return;
      
      final usersStr = _prefs!.getString('users');
      if (usersStr != null) {
        final List list = jsonDecode(usersStr);
        _users.addAll(list.map((e) => User.fromJson(e)));
      }
      
      final sectionsStr = _prefs!.getString('sections');
      if (sectionsStr != null) {
        final List list = jsonDecode(sectionsStr);
        _sections.addAll(list.map((e) => Section.fromJson(e)));
      }
      
      final rehearsalsStr = _prefs!.getString('rehearsals');
      if (rehearsalsStr != null) {
        final List list = jsonDecode(rehearsalsStr);
        _rehearsals.addAll(list.map((e) => Rehearsal.fromJson(e)));
      }
      
      final checkInsStr = _prefs!.getString('checkIns');
      if (checkInsStr != null) {
        final List list = jsonDecode(checkInsStr);
        _checkIns.addAll(list.map((e) => CheckIn.fromJson(e)));
      }
      
      final helpReqStr = _prefs!.getString('helpRequests');
      if (helpReqStr != null) {
        final List list = jsonDecode(helpReqStr);
        _helpRequests.addAll(list.map((e) => HelpRequest.fromJson(e)));
      }
      
      final alertsStr = _prefs!.getString('alerts');
      if (alertsStr != null) {
        final List list = jsonDecode(alertsStr);
        _alerts.addAll(list.map((e) => Alert.fromJson(e)));
      }

      // Also parse trips etc if needed, but not strictly needed for wellness demo.
      final tripsStr = _prefs!.getString('trips');
      if (tripsStr != null) {
        final List list = jsonDecode(tripsStr);
        _trips.addAll(list.map((e) => Trip.fromJson(e)));
      }

      final tripStudentsStr = _prefs!.getString('tripStudents');
      if (tripStudentsStr != null) {
        final List list = jsonDecode(tripStudentsStr);
        _tripStudents.addAll(list.map((e) => TripStudent.fromJson(e)));
      }

      final scanEventsStr = _prefs!.getString('scanEvents');
      if (scanEventsStr != null) {
        final List list = jsonDecode(scanEventsStr);
        _scanEvents.addAll(list.map((e) => ScanEvent.fromJson(e)));
      }

    } catch (e) {
      debugPrint('Failed to load demo data from prefs: $e');
      _initializeDemoData();
    }
  }

  Future<void> _saveToPrefs() async {
    if (_prefs == null) return;
    try {
      await _prefs!.setString('users', jsonEncode(_users.map((e) => e.toJson()).toList()));
      await _prefs!.setString('sections', jsonEncode(_sections.map((e) => e.toJson()).toList()));
      await _prefs!.setString('rehearsals', jsonEncode(_rehearsals.map((e) => e.toJson()).toList()));
      await _prefs!.setString('checkIns', jsonEncode(_checkIns.map((e) => e.toJson()).toList()));
      await _prefs!.setString('helpRequests', jsonEncode(_helpRequests.map((e) => e.toJson()).toList()));
      await _prefs!.setString('alerts', jsonEncode(_alerts.map((e) => e.toJson()).toList()));
      await _prefs!.setString('trips', jsonEncode(_trips.map((e) => e.toJson()).toList()));
      await _prefs!.setString('tripStudents', jsonEncode(_tripStudents.map((e) => e.toJson()).toList()));
      await _prefs!.setString('scanEvents', jsonEncode(_scanEvents.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('Failed to save demo data to prefs: $e');
    }
  }
  
  void _initializeDemoData() {
    // Sections
    final sectionNames = [
      'Flute', 'Clarinet', 'Saxophone', 'Trumpet', 'Mellophone', 
      'Trombone', 'Baritone / Euphonium', 'Tuba / Sousaphone', 
      'Percussion', 'Front Ensemble', 'Color Guard', 'Drum Major'
    ];
    
    for (var name in sectionNames) {
      _sections.add(Section(sectionId: _uuid.v4(), name: name));
    }
    
    final percussionId = _sections.firstWhere((s) => s.name == 'Percussion').sectionId;
    final trumpetId = _sections.firstWhere((s) => s.name == 'Trumpet').sectionId;
    final fluteId = _sections.firstWhere((s) => s.name == 'Flute').sectionId;
    final clarinetId = _sections.firstWhere((s) => s.name == 'Clarinet').sectionId;
    
    // Users
    _users.add(User(
      userId: 'staff_1',
      firstName: 'Director',
      role: UserRole.staff,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ));
    
    for (int i = 1; i <= 20; i++) {
      String secId = _sections[i % _sections.length].sectionId;
      if (i <= 4) secId = percussionId;
      if (i > 4 && i <= 7) secId = trumpetId;
      if (i > 7 && i <= 10) secId = clarinetId;
      if (i == 20) secId = fluteId; // Student 20 is Flute
      
      _users.add(User(
        userId: 'student_$i',
        firstName: 'DemoStudent$i',
        role: UserRole.student,
        sectionId: secId,
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
      ));
    }
    
    // Rehearsals (4 weeks, 2 per week = 8 rehearsals)
    final now = DateTime.now();
    for (int i = 7; i >= 0; i--) {
      _rehearsals.add(Rehearsal(
        rehearsalId: 'reh_$i',
        date: now.subtract(Duration(days: i * 3)),
        status: i == 0 ? 'active' : 'closed',
      ));
    }
    final todayRehearsal = _rehearsals.last;
    
    // One student with recurring fatigue (Student 2 - Percussion)
    _checkIns.add(CheckIn(checkinId: _uuid.v4(), userId: 'student_2', rehearsalId: _rehearsals[5].rehearsalId, sectionId: percussionId, concerns: ['Very Tired'], timestamp: _rehearsals[5].date.add(const Duration(minutes: 10))));
    _checkIns.add(CheckIn(checkinId: _uuid.v4(), userId: 'student_2', rehearsalId: _rehearsals[6].rehearsalId, sectionId: percussionId, concerns: ['Very Tired'], timestamp: _rehearsals[6].date.add(const Duration(minutes: 10))));
    _checkIns.add(CheckIn(checkinId: _uuid.v4(), userId: 'student_2', rehearsalId: _rehearsals[7].rehearsalId, sectionId: percussionId, concerns: ['Very Tired'], timestamp: _rehearsals[7].date.add(const Duration(minutes: 10))));

    // One student with recurring knee discomfort (Student 3 - Percussion)
    _checkIns.add(CheckIn(checkinId: _uuid.v4(), userId: 'student_3', rehearsalId: _rehearsals[4].rehearsalId, sectionId: percussionId, concerns: ['Pain / Discomfort'], bodyArea: 'Knee', timestamp: _rehearsals[4].date.add(const Duration(minutes: 5))));
    _checkIns.add(CheckIn(checkinId: _uuid.v4(), userId: 'student_3', rehearsalId: _rehearsals[5].rehearsalId, sectionId: percussionId, concerns: ['Pain / Discomfort'], bodyArea: 'Knee', timestamp: _rehearsals[5].date.add(const Duration(minutes: 5))));
    _checkIns.add(CheckIn(checkinId: _uuid.v4(), userId: 'student_3', rehearsalId: _rehearsals[7].rehearsalId, sectionId: percussionId, concerns: ['Pain / Discomfort'], bodyArea: 'Knee', timestamp: _rehearsals[7].date.add(const Duration(minutes: 5))));

    // One section with multiple overheating reports (Trumpets today)
    _checkIns.add(CheckIn(checkinId: _uuid.v4(), userId: 'student_5', rehearsalId: todayRehearsal.rehearsalId, sectionId: trumpetId, concerns: ['Overheated / Unwell'], timestamp: todayRehearsal.date.add(const Duration(minutes: 15))));
    _checkIns.add(CheckIn(checkinId: _uuid.v4(), userId: 'student_6', rehearsalId: todayRehearsal.rehearsalId, sectionId: trumpetId, concerns: ['Overheated / Unwell'], timestamp: todayRehearsal.date.add(const Duration(minutes: 16))));
    _checkIns.add(CheckIn(checkinId: _uuid.v4(), userId: 'student_7', rehearsalId: todayRehearsal.rehearsalId, sectionId: trumpetId, concerns: ['Overheated / Unwell'], timestamp: todayRehearsal.date.add(const Duration(minutes: 17))));

    // One new student with improving comfort ratings (Student 8 - Clarinet)
    _checkIns.add(CheckIn(checkinId: _uuid.v4(), userId: 'student_8', rehearsalId: _rehearsals[4].rehearsalId, sectionId: clarinetId, concerns: ['Feeling Good'], rehearsalComfort: 2, confidenceManagingDemands: 2, timestamp: _rehearsals[4].date.add(const Duration(minutes: 5))));
    _checkIns.add(CheckIn(checkinId: _uuid.v4(), userId: 'student_8', rehearsalId: _rehearsals[5].rehearsalId, sectionId: clarinetId, concerns: ['Feeling Good'], rehearsalComfort: 3, confidenceManagingDemands: 3, timestamp: _rehearsals[5].date.add(const Duration(minutes: 5))));
    _checkIns.add(CheckIn(checkinId: _uuid.v4(), userId: 'student_8', rehearsalId: _rehearsals[6].rehearsalId, sectionId: clarinetId, concerns: ['Feeling Good'], rehearsalComfort: 4, confidenceManagingDemands: 3, timestamp: _rehearsals[6].date.add(const Duration(minutes: 5))));
    _checkIns.add(CheckIn(checkinId: _uuid.v4(), userId: 'student_8', rehearsalId: _rehearsals[7].rehearsalId, sectionId: clarinetId, concerns: ['Feeling Good'], rehearsalComfort: 5, confidenceManagingDemands: 4, timestamp: _rehearsals[7].date.add(const Duration(minutes: 5))));

    // One student with stable check-ins and no detected pattern (Student 9 - Clarinet)
    for (int i = 4; i <= 7; i++) {
      _checkIns.add(CheckIn(checkinId: _uuid.v4(), userId: 'student_9', rehearsalId: _rehearsals[i].rehearsalId, sectionId: clarinetId, concerns: ['Feeling Good'], rehearsalComfort: 4, confidenceManagingDemands: 4, timestamp: _rehearsals[i].date.add(const Duration(minutes: 5))));
    }

    // Existing test: Demo Student A reporting 'Dizzy / Lightheaded'
    _users.add(User(
      userId: 'student_A',
      firstName: 'Demo Student A',
      role: UserRole.student,
      sectionId: fluteId,
      createdAt: DateTime(2026, 1, 1),
    ));

    _rehearsals.add(Rehearsal(rehearsalId: 'reh_oct10', date: DateTime(2026, 10, 10), status: 'closed'));
    _rehearsals.add(Rehearsal(rehearsalId: 'reh_oct14', date: DateTime(2026, 10, 14), status: 'closed'));
    _rehearsals.add(Rehearsal(rehearsalId: 'reh_oct18', date: DateTime(2026, 10, 18), status: 'closed'));

    _checkIns.add(CheckIn(checkinId: 'chk_oct10', userId: 'student_A', rehearsalId: 'reh_oct10', sectionId: fluteId, concerns: ['Dizzy / Lightheaded'], timestamp: DateTime(2026, 10, 10, 15, 0)));
    _checkIns.add(CheckIn(checkinId: 'chk_oct14', userId: 'student_A', rehearsalId: 'reh_oct14', sectionId: fluteId, concerns: ['Dizzy / Lightheaded'], timestamp: DateTime(2026, 10, 14, 15, 0)));
    _checkIns.add(CheckIn(checkinId: 'chk_oct18', userId: 'student_A', rehearsalId: 'reh_oct18', sectionId: fluteId, concerns: ['Dizzy / Lightheaded'], timestamp: DateTime(2026, 10, 18, 15, 0)));

    
    _checkPatterns();
    
    // Active Help Request
    _helpRequests.add(HelpRequest(
      requestId: _uuid.v4(),
      userId: 'student_2',
      sectionId: percussionId,
      concern: 'Very Tired',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      status: 'Pending',
      auditHistory: [
        HelpRequestAudit(
          status: 'Pending',
          staffId: 'system',
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        )
      ]
    ));

    // TripGuard Demo Data
    final demoTrip = Trip(
      tripId: 'trip_1',
      name: 'State Championship Finals',
      date: DateTime.now(),
      destination: 'State Stadium',
      departureTime: DateTime.now().add(const Duration(hours: 2)),
      status: 'Active',
    );
    _trips.add(demoTrip);

    // Assign students to trip
    for (var u in _users.where((u) => u.role == UserRole.student)) {
      _tripStudents.add(TripStudent(
        tripId: demoTrip.tripId,
        userId: u.userId,
        busId: u.userId == 'student_1' || u.userId == 'student_2' ? 'Bus 1' : 'Bus 2',
        qrToken: _uuid.v4(),
      ));
    }

    _scanEvents.add(ScanEvent(
      scanId: _uuid.v4(),
      tripId: demoTrip.tripId,
      userId: 'student_3',
      scannedByStaffId: 'staff_1',
      scannedBusId: 'Bus 1',
      expectedBusId: 'Bus 2',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      checkpoint: 'Boarding',
      isConflict: true,
    ));
  }
  
  void _checkPatterns() {
    _alerts.clear();
    final today = _rehearsals.last;
    
    // Feature 1: Individual Patterns (3 distinct rehearsals in a rolling 14-day period)
    
    // Group check-ins by user
    final allCheckIns = [..._checkIns, ..._externalCheckIns];
    final userCheckIns = <String, List<CheckIn>>{};
    for (var checkIn in allCheckIns) {
      userCheckIns.putIfAbsent(checkIn.userId, () => []).add(checkIn);
    }
    
    userCheckIns.forEach((userId, userChecks) {
      // Group by concern
      final concernDates = <String, Set<String>>{};
      for (var checkIn in userChecks) {
        for (var concern in checkIn.concerns) {
          if (concern != 'Feeling Good') {
            concernDates.putIfAbsent(concern, () => {}).add(checkIn.rehearsalId);
          }
        }
      }
      
      concernDates.forEach((concern, rehearsalIds) {
        if (rehearsalIds.length >= 3) {
          // Find actual dates
          final dates = rehearsalIds.map((rId) {
            return _rehearsals.firstWhere((r) => r.rehearsalId == rId).date;
          }).toList();
          dates.sort();
          
          bool patternFound = false;
          List<DateTime> patternDates = [];
          for (int i = 0; i <= dates.length - 3; i++) {
            if (dates[i + 2].difference(dates[i]).inDays <= 14) {
              patternFound = true;
              patternDates = [dates[i], dates[i + 1], dates[i + 2]];
              break;
            }
          }
          
          if (patternFound) {
            _alerts.add(Alert(
              alertId: _uuid.v4(),
              type: 'individual',
              sectionId: userChecks.first.sectionId,
              concern: concern,
              reportCount: patternDates.length, // using the pattern instances
              createdAt: DateTime.now(),
              status: 'active',
              userId: userId,
              rehearsalDates: patternDates,
            ));
          }
        }
      });
    });
    
    // Feature 2: Section Patterns (3 distinct students today)
    final sectionConcernUsers = <String, Map<String, Set<String>>>{};
    
    for (var checkIn in _checkIns) {
      if (checkIn.rehearsalId != today.rehearsalId) continue;
      
      sectionConcernUsers.putIfAbsent(checkIn.sectionId, () => {});
      
      for (var concern in checkIn.concerns) {
        if (concern != 'Feeling Good') {
          sectionConcernUsers[checkIn.sectionId]!.putIfAbsent(concern, () => {}).add(checkIn.userId);
        }
      }
    }
    
    sectionConcernUsers.forEach((sectionId, concernUsers) {
      concernUsers.forEach((concern, users) {
        if (users.length >= 3) {
          _alerts.add(Alert(
            alertId: _uuid.v4(),
            type: 'section',
            rehearsalId: today.rehearsalId,
            sectionId: sectionId,
            concern: concern,
            reportCount: users.length,
            createdAt: DateTime.now(),
            status: 'active',
          ));
        }
      });
    });
  }

  @override
  Future<User?> login(String username, String role) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      if (role == UserRole.staff) {
        _currentUser = _users.firstWhere((u) => u.role == UserRole.staff);
      } else {
        _currentUser = _users.firstWhere((u) => u.role == UserRole.student);
      }
      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Section>> getSections() async {
    return List.from(_sections);
  }

  @override
  Future<Rehearsal?> getCurrentRehearsal() async {
    if (_rehearsals.isNotEmpty) return _rehearsals.last;
    return null;
  }

  @override
  Future<User?> getUser(String userId) async {
    try {
      return _users.firstWhere((u) => u.userId == userId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> submitCheckIn(CheckIn checkIn) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _checkIns.add(checkIn);
    _checkPatterns();
    await _saveToPrefs();
  }

  @override
  Future<void> submitHelpRequest(HelpRequest request) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _helpRequests.add(request);
    await _saveToPrefs();
  }

  @override
  Future<List<CheckIn>> getTodayCheckIns() async {
    return List.from(_checkIns);
  }

  @override
  Future<List<HelpRequest>> getActiveHelpRequests() async {
    return _helpRequests.where((r) => r.status != 'Resolved').toList();
  }

  @override
  Future<List<Alert>> getActiveAlerts() async {
    return _alerts.where((a) => a.status == 'active').toList();
  }

  @override
  Future<void> acknowledgeHelpRequest(String requestId, String staffId) async {
    await updateHelpRequestStatus(requestId, 'Acknowledged', staffId);
  }

  @override
  Future<void> updateHelpRequestStatus(String requestId, String status, String staffId, {String? note}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _helpRequests.indexWhere((r) => r.requestId == requestId);
    if (index != -1) {
      final req = _helpRequests[index];
      final newAudit = HelpRequestAudit(
        status: status,
        staffId: staffId,
        timestamp: DateTime.now(),
        note: note,
      );
      _helpRequests[index] = req.copyWith(
        status: status,
        acknowledgedAt: status == 'Acknowledged' ? DateTime.now() : req.acknowledgedAt,
        auditHistory: [...req.auditHistory, newAudit],
      );
      await _saveToPrefs();
    }
  }

  @override
  Future<List<Rehearsal>> getRehearsals() async {
    return List.from(_rehearsals);
  }

  @override
  Future<List<CheckIn>> getAllCheckIns() async {
    return List.from(_checkIns);
  }

  @override
  Future<void> reviewAlert(String alertId, String staffId, String note) async {
    final idx = _alerts.indexWhere((a) => a.alertId == alertId);
    if (idx != -1) {
      final alert = _alerts[idx];
      final newReview = AlertReview(
        staffId: staffId,
        timestamp: DateTime.now(),
        note: note,
      );
      _alerts[idx] = alert.copyWith(
        status: 'reviewed',
        reviews: [...alert.reviews, newReview],
      );
      await _saveToPrefs();
    }
  }

  // TripGuard Implementations
  @override
  Future<List<Trip>> getActiveTrips() async {
    return _trips.where((t) => t.status == 'Active').toList();
  }

  @override
  Future<Trip?> getTrip(String tripId) async {
    try {
      return _trips.firstWhere((t) => t.tripId == tripId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createTrip(Trip trip) async {
    _trips.add(trip);
    await _saveToPrefs();
  }

  @override
  Future<void> closeTrip(String tripId) async {
    final idx = _trips.indexWhere((t) => t.tripId == tripId);
    if (idx != -1) {
      _trips[idx] = _trips[idx].copyWith(status: 'Closed');
      await _saveToPrefs();
    }
  }

  @override
  Future<List<TripStudent>> getTripStudents(String tripId) async {
    return _tripStudents.where((ts) => ts.tripId == tripId).toList();
  }

  @override
  Future<TripStudent?> getTripStudentByUser(String tripId, String userId) async {
    try {
      return _tripStudents.firstWhere((ts) => ts.tripId == tripId && ts.userId == userId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> assignStudentToTrip(TripStudent student) async {
    _tripStudents.add(student);
    await _saveToPrefs();
  }

  @override
  Future<void> recordScanEvent(ScanEvent event) async {
    _scanEvents.add(event);
    
    // Check for conflicts
    final otherScans = _scanEvents.where((e) => e.tripId == event.tripId && e.userId == event.userId && e.scanId != event.scanId && !e.isResolved).toList();
    if (otherScans.isNotEmpty) {
      // Mark all as conflict
      for (var s in otherScans) {
        final idx = _scanEvents.indexWhere((e) => e.scanId == s.scanId);
        _scanEvents[idx] = _scanEvents[idx].copyWith(isConflict: true);
      }
      final idx = _scanEvents.indexWhere((e) => e.scanId == event.scanId);
      _scanEvents[idx] = _scanEvents[idx].copyWith(isConflict: true);
    }
    await _saveToPrefs();
  }

  @override
  Future<List<ScanEvent>> getTripScans(String tripId) async {
    return _scanEvents.where((e) => e.tripId == tripId).toList();
  }

  @override
  Future<void> resolveScanConflict(String scanId, String staffId, String note) async {
    final idx = _scanEvents.indexWhere((e) => e.scanId == scanId);
    if (idx != -1) {
      _scanEvents[idx] = _scanEvents[idx].copyWith(
        isResolved: true,
        resolutionNote: note,
        isConflict: false, // Resolved
      );
      
      // Also resolve other conflicts for this student in this trip
      final event = _scanEvents[idx];
      final others = _scanEvents.where((e) => e.tripId == event.tripId && e.userId == event.userId && e.isConflict).toList();
      for (var o in others) {
        final oIdx = _scanEvents.indexWhere((e) => e.scanId == o.scanId);
        _scanEvents[oIdx] = _scanEvents[oIdx].copyWith(
          isResolved: true,
          resolutionNote: 'Resolved by another scan: $note',
          isConflict: false,
        );
      }
      await _saveToPrefs();
    }
  }

  @override
  Future<void> loadDemoScenario(int scenarioId) async {
    // Currently unimplemented demo functionality
  }

  bool _demoTestActive = true;
  CheckIn? _demoTestRecord;

  @override
  bool get isDemoTestActive => _demoTestActive;

  @override
  List<CheckIn> get demoTestCheckIns {
    final active = _checkIns.where((c) => c.userId == 'student_A' && (c.rehearsalId == 'reh_oct10' || c.rehearsalId == 'reh_oct14' || c.rehearsalId == 'reh_oct18')).toList();
    if (_demoTestRecord != null) {
      active.add(_demoTestRecord!);
    }
    active.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return active;
  }

  @override
  Future<void> toggleDemoTest() async {
    if (_demoTestActive) {
      // Remove one of Demo Student A's records
      final idx = _checkIns.indexWhere((c) => c.userId == 'student_A' && c.rehearsalId == 'reh_oct14');
      if (idx != -1) {
        _demoTestRecord = _checkIns.removeAt(idx);
        _demoTestActive = false;
      }
    } else {
      // Restore the record
      if (_demoTestRecord != null) {
        _checkIns.add(_demoTestRecord!);
        _demoTestRecord = null;
        _demoTestActive = true;
      }
    }
    _checkPatterns();
    await _saveToPrefs();
  }

  final List<CheckIn> _externalCheckIns = [];

  @override
  void updateExternalCheckIns(List<CheckIn> checkIns) {
    _externalCheckIns.clear();
    _externalCheckIns.addAll(checkIns);
    _checkPatterns();
    _saveToPrefs();
  }

  @override
  Future<void> setupDemoAccounts() async {
    // InMemory does nothing or minimal mock
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> resetDemoData() async {
    _users.clear();
    _sections.clear();
    _rehearsals.clear();
    _checkIns.clear();
    _helpRequests.clear();
    _alerts.clear();
    _trips.clear();
    _tripStudents.clear();
    _scanEvents.clear();
    _externalCheckIns.clear();
    _currentUser = null;
    _initializeDemoData();
    await _saveToPrefs();
  }
}

// Global instance for simple access
DataService dataService = InMemoryDataService();
