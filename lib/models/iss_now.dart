class IssPosition {
  final double latitude;
  final double longitude;

  IssPosition({required this.latitude, required this.longitude});

  factory IssPosition.fromJson(Map<String, dynamic> json) {
    return IssPosition(
      latitude: double.parse(json['latitude'] as String),
      longitude: double.parse(json['longitude'] as String),
    );
  }
}

class IssNow {
  final IssPosition position;
  final DateTime timestamp;

  IssNow({required this.position, required this.timestamp});

  factory IssNow.fromJson(Map<String, dynamic> json) {
    return IssNow(
      position: IssPosition.fromJson(json['iss_position'] as Map<String, dynamic>),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] as int) * 1000,
      ),
    );
  }
}
