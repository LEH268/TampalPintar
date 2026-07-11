class Draft {
  Draft({
    required this.id,
    required this.capturedAt,
    required this.lat,
    required this.lng,
    this.speedKmh,
    List<String>? mediaPaths,
    this.immediateIndex,
    this.vehicleType,
    this.lanePosition,
    this.impactSeverity,
  }) : mediaPaths = mediaPaths ?? [];

  final String id;
  final DateTime capturedAt;
  final double lat;
  final double lng;
  final double? speedKmh;
  List<String> mediaPaths;
  int? immediateIndex;
  String? vehicleType;
  String? lanePosition;
  String? impactSeverity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
        'lat': lat,
        'lng': lng,
        'speedKmh': speedKmh,
        'mediaPaths': mediaPaths,
        'immediateIndex': immediateIndex,
        'vehicleType': vehicleType,
        'lanePosition': lanePosition,
        'impactSeverity': impactSeverity,
      };

  factory Draft.fromJson(Map<String, dynamic> j) => Draft(
        id: j['id'] as String,
        capturedAt: DateTime.parse(j['capturedAt'] as String),
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        speedKmh: (j['speedKmh'] as num?)?.toDouble(),
        mediaPaths: [...(j['mediaPaths'] as List? ?? []).cast<String>()],
        immediateIndex: j['immediateIndex'] as int?,
        vehicleType: j['vehicleType'] as String?,
        lanePosition: j['lanePosition'] as String?,
        impactSeverity: j['impactSeverity'] as String?,
      );
}
