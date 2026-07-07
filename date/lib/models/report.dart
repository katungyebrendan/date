import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_reason.dart';

class Report {
  final String reporterUid;
  final String reportedUid;
  final ReportReason reason;
  final String details;

  const Report({
    required this.reporterUid,
    required this.reportedUid,
    required this.reason,
    this.details = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'reporterUid': reporterUid,
      'reportedUid': reportedUid,
      'reason': reason.value,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
