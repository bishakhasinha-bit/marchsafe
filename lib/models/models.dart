class UserRole {
  static const String student = 'student';
  static const String staff = 'staff';
}

class User {
  final String userId;
  final String firstName;
  final String role;
  final String? sectionId;
  final DateTime createdAt;

  User({
    required this.userId,
    required this.firstName,
    required this.role,
    this.sectionId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'firstName': firstName,
    'role': role,
    'sectionId': sectionId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    userId: json['userId'],
    firstName: json['firstName'],
    role: json['role'],
    sectionId: json['sectionId'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class Section {
  final String sectionId;
  final String name;

  Section({
    required this.sectionId,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    'sectionId': sectionId,
    'name': name,
  };

  factory Section.fromJson(Map<String, dynamic> json) => Section(
    sectionId: json['sectionId'],
    name: json['name'],
  );
}

class Rehearsal {
  final String rehearsalId;
  final DateTime date;
  final String status;

  Rehearsal({
    required this.rehearsalId,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'rehearsalId': rehearsalId,
    'date': date.toIso8601String(),
    'status': status,
  };

  factory Rehearsal.fromJson(Map<String, dynamic> json) => Rehearsal(
    rehearsalId: json['rehearsalId'],
    date: DateTime.parse(json['date']),
    status: json['status'],
  );
}

class CheckIn {
  final String checkinId;
  final String userId;
  final String rehearsalId;
  final String sectionId;
  final List<String> concerns;
  final String? bodyArea;
  final int? rehearsalComfort;
  final int? confidenceManagingDemands;
  final DateTime timestamp;

  CheckIn({
    required this.checkinId,
    required this.userId,
    required this.rehearsalId,
    required this.sectionId,
    required this.concerns,
    this.bodyArea,
    this.rehearsalComfort,
    this.confidenceManagingDemands,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'checkinId': checkinId,
    'userId': userId,
    'rehearsalId': rehearsalId,
    'sectionId': sectionId,
    'concerns': concerns,
    'bodyArea': bodyArea,
    'rehearsalComfort': rehearsalComfort,
    'confidenceManagingDemands': confidenceManagingDemands,
    'timestamp': timestamp.toIso8601String(),
  };

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
    checkinId: json['checkinId'],
    userId: json['userId'],
    rehearsalId: json['rehearsalId'],
    sectionId: json['sectionId'],
    concerns: List<String>.from(json['concerns']),
    bodyArea: json['bodyArea'],
    rehearsalComfort: json['rehearsalComfort'],
    confidenceManagingDemands: json['confidenceManagingDemands'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class HelpRequestAudit {
  final String status;
  final String staffId;
  final DateTime timestamp;
  final String? note;

  HelpRequestAudit({
    required this.status,
    required this.staffId,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'status': status,
    'staffId': staffId,
    'timestamp': timestamp.toIso8601String(),
    'note': note,
  };

  factory HelpRequestAudit.fromJson(Map<String, dynamic> json) => HelpRequestAudit(
    status: json['status'],
    staffId: json['staffId'],
    timestamp: DateTime.parse(json['timestamp']),
    note: json['note'],
  );
}

class HelpRequest {
  final String requestId;
  final String userId;
  final String sectionId;
  final String concern;
  final DateTime timestamp;
  final String status;
  final DateTime? acknowledgedAt;
  final List<HelpRequestAudit> auditHistory;

  HelpRequest({
    required this.requestId,
    required this.userId,
    required this.sectionId,
    required this.concern,
    required this.timestamp,
    required this.status,
    this.acknowledgedAt,
    this.auditHistory = const [],
  });

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'userId': userId,
    'sectionId': sectionId,
    'concern': concern,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
    'acknowledgedAt': acknowledgedAt?.toIso8601String(),
    'auditHistory': auditHistory.map((a) => a.toJson()).toList(),
  };

  factory HelpRequest.fromJson(Map<String, dynamic> json) => HelpRequest(
    requestId: json['requestId'],
    userId: json['userId'],
    sectionId: json['sectionId'],
    concern: json['concern'],
    timestamp: DateTime.parse(json['timestamp']),
    status: json['status'],
    acknowledgedAt: json['acknowledgedAt'] != null ? DateTime.parse(json['acknowledgedAt']) : null,
    auditHistory: (json['auditHistory'] as List?)?.map((a) => HelpRequestAudit.fromJson(a)).toList() ?? [],
  );

  HelpRequest copyWith({
    String? requestId,
    String? userId,
    String? sectionId,
    String? concern,
    DateTime? timestamp,
    String? status,
    DateTime? acknowledgedAt,
    List<HelpRequestAudit>? auditHistory,
  }) {
    return HelpRequest(
      requestId: requestId ?? this.requestId,
      userId: userId ?? this.userId,
      sectionId: sectionId ?? this.sectionId,
      concern: concern ?? this.concern,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      auditHistory: auditHistory ?? this.auditHistory,
    );
  }
}

class AlertReview {
  final String staffId;
  final DateTime timestamp;
  final String? note;

  AlertReview({
    required this.staffId,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'staffId': staffId,
    'timestamp': timestamp.toIso8601String(),
    'note': note,
  };

  factory AlertReview.fromJson(Map<String, dynamic> json) => AlertReview(
    staffId: json['staffId'],
    timestamp: DateTime.parse(json['timestamp']),
    note: json['note'],
  );
}

class Alert {
  final String alertId;
  final String type;
  final String? rehearsalId;
  final String sectionId;
  final String concern;
  final int reportCount;
  final DateTime createdAt;
  final String status;
  final String? userId;
  final List<DateTime> rehearsalDates;
  final List<AlertReview> reviews;

  Alert({
    required this.alertId,
    required this.type,
    this.rehearsalId,
    required this.sectionId,
    required this.concern,
    required this.reportCount,
    required this.createdAt,
    required this.status,
    this.userId,
    this.rehearsalDates = const [],
    this.reviews = const [],
  });

  Map<String, dynamic> toJson() => {
    'alertId': alertId,
    'type': type,
    'rehearsalId': rehearsalId,
    'sectionId': sectionId,
    'concern': concern,
    'reportCount': reportCount,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
    'userId': userId,
    'rehearsalDates': rehearsalDates.map((d) => d.toIso8601String()).toList(),
    'reviews': reviews.map((r) => r.toJson()).toList(),
  };

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
    alertId: json['alertId'],
    type: json['type'],
    rehearsalId: json['rehearsalId'],
    sectionId: json['sectionId'],
    concern: json['concern'],
    reportCount: json['reportCount'],
    createdAt: DateTime.parse(json['createdAt']),
    status: json['status'],
    userId: json['userId'],
    rehearsalDates: (json['rehearsalDates'] as List?)?.map((d) => DateTime.parse(d)).toList() ?? [],
    reviews: (json['reviews'] as List?)?.map((r) => AlertReview.fromJson(r)).toList() ?? [],
  );

  Alert copyWith({
    String? status,
    List<AlertReview>? reviews,
  }) {
    return Alert(
      alertId: alertId,
      type: type,
      rehearsalId: rehearsalId,
      sectionId: sectionId,
      concern: concern,
      reportCount: reportCount,
      createdAt: createdAt,
      status: status ?? this.status,
      userId: userId,
      rehearsalDates: rehearsalDates,
      reviews: reviews ?? this.reviews,
    );
  }
}

class Trip {
  final String tripId;
  final String name;
  final DateTime date;
  final String destination;
  final DateTime departureTime;
  final String status;

  Trip({
    required this.tripId,
    required this.name,
    required this.date,
    required this.destination,
    required this.departureTime,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'tripId': tripId,
    'name': name,
    'date': date.toIso8601String(),
    'destination': destination,
    'departureTime': departureTime.toIso8601String(),
    'status': status,
  };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    tripId: json['tripId'],
    name: json['name'],
    date: DateTime.parse(json['date']),
    destination: json['destination'],
    departureTime: DateTime.parse(json['departureTime']),
    status: json['status'],
  );

  Trip copyWith({
    String? tripId,
    String? name,
    DateTime? date,
    String? destination,
    DateTime? departureTime,
    String? status,
  }) {
    return Trip(
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      date: date ?? this.date,
      destination: destination ?? this.destination,
      departureTime: departureTime ?? this.departureTime,
      status: status ?? this.status,
    );
  }
}

class TripStudent {
  final String tripId;
  final String userId;
  final String busId;
  final String qrToken;

  TripStudent({
    required this.tripId,
    required this.userId,
    required this.busId,
    required this.qrToken,
  });

  Map<String, dynamic> toJson() => {
    'tripId': tripId,
    'userId': userId,
    'busId': busId,
    'qrToken': qrToken,
  };

  factory TripStudent.fromJson(Map<String, dynamic> json) => TripStudent(
    tripId: json['tripId'],
    userId: json['userId'],
    busId: json['busId'],
    qrToken: json['qrToken'],
  );
}

class ScanEvent {
  final String scanId;
  final String tripId;
  final String userId;
  final String scannedByStaffId;
  final String scannedBusId;
  final String expectedBusId;
  final DateTime timestamp;
  final String checkpoint;
  final bool isConflict;
  final bool isResolved;
  final String? resolutionNote;

  ScanEvent({
    required this.scanId,
    required this.tripId,
    required this.userId,
    required this.scannedByStaffId,
    required this.scannedBusId,
    required this.expectedBusId,
    required this.timestamp,
    required this.checkpoint,
    this.isConflict = false,
    this.isResolved = false,
    this.resolutionNote,
  });

  Map<String, dynamic> toJson() => {
    'scanId': scanId,
    'tripId': tripId,
    'userId': userId,
    'scannedByStaffId': scannedByStaffId,
    'scannedBusId': scannedBusId,
    'expectedBusId': expectedBusId,
    'timestamp': timestamp.toIso8601String(),
    'checkpoint': checkpoint,
    'isConflict': isConflict,
    'isResolved': isResolved,
    'resolutionNote': resolutionNote,
  };

  factory ScanEvent.fromJson(Map<String, dynamic> json) => ScanEvent(
    scanId: json['scanId'],
    tripId: json['tripId'],
    userId: json['userId'],
    scannedByStaffId: json['scannedByStaffId'],
    scannedBusId: json['scannedBusId'],
    expectedBusId: json['expectedBusId'],
    timestamp: DateTime.parse(json['timestamp']),
    checkpoint: json['checkpoint'],
    isConflict: json['isConflict'] ?? false,
    isResolved: json['isResolved'] ?? false,
    resolutionNote: json['resolutionNote'],
  );

  ScanEvent copyWith({
    String? scanId,
    String? tripId,
    String? userId,
    String? scannedByStaffId,
    String? scannedBusId,
    String? expectedBusId,
    DateTime? timestamp,
    String? checkpoint,
    bool? isConflict,
    bool? isResolved,
    String? resolutionNote,
  }) {
    return ScanEvent(
      scanId: scanId ?? this.scanId,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      scannedByStaffId: scannedByStaffId ?? this.scannedByStaffId,
      scannedBusId: scannedBusId ?? this.scannedBusId,
      expectedBusId: expectedBusId ?? this.expectedBusId,
      timestamp: timestamp ?? this.timestamp,
      checkpoint: checkpoint ?? this.checkpoint,
      isConflict: isConflict ?? this.isConflict,
      isResolved: isResolved ?? this.isResolved,
      resolutionNote: resolutionNote ?? this.resolutionNote,
    );
  }
}
