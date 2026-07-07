enum ReportReason { inappropriatePhotos, harassment, fakeProfile, spam, underage, other }

extension ReportReasonCodec on ReportReason {
  String get value => name;

  String get label {
    switch (this) {
      case ReportReason.inappropriatePhotos:
        return 'Inappropriate photos';
      case ReportReason.harassment:
        return 'Harassment or threats';
      case ReportReason.fakeProfile:
        return 'Fake profile';
      case ReportReason.spam:
        return 'Spam or scam';
      case ReportReason.underage:
        return 'Underage user';
      case ReportReason.other:
        return 'Other';
    }
  }

  static ReportReason fromValue(String value) {
    return ReportReason.values.firstWhere(
      (r) => r.value == value,
      orElse: () => ReportReason.other,
    );
  }
}
