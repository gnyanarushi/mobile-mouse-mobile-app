/// Model for storing connection information
class ConnectionInfo {
  final String host;
  final int tcpPort;
  final int udpPort;
  final String nickname;
  final DateTime lastUsed;

  ConnectionInfo({
    required this.host,
    required this.tcpPort,
    required this.udpPort,
    required this.nickname,
    required this.lastUsed,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'tcpPort': tcpPort,
      'udpPort': udpPort,
      'nickname': nickname,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  // Create from JSON
  factory ConnectionInfo.fromJson(Map<String, dynamic> json) {
    return ConnectionInfo(
      host: json['host'] as String,
      tcpPort: json['tcpPort'] as int,
      udpPort: json['udpPort'] as int,
      nickname: json['nickname'] as String,
      lastUsed: DateTime.parse(json['lastUsed'] as String),
    );
  }

  // Create a copy with updated fields
  ConnectionInfo copyWith({
    String? host,
    int? tcpPort,
    int? udpPort,
    String? nickname,
    DateTime? lastUsed,
  }) {
    return ConnectionInfo(
      host: host ?? this.host,
      tcpPort: tcpPort ?? this.tcpPort,
      udpPort: udpPort ?? this.udpPort,
      nickname: nickname ?? this.nickname,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  @override
  String toString() => '$nickname ($host:$tcpPort)';
}
