/// Mirrors the `potholes` table. Status/road_type/assigned_role are kept as
/// plain strings (they're already validated by DB enums) rather than
/// mirrored into Dart enums -- one less thing to keep in sync by hand.
class Pothole {
  Pothole({
    required this.id,
    required this.photoUrl,
    required this.lat,
    required this.lng,
    required this.status,
    required this.riskScore,
    required this.riskRationale,
    required this.roadType,
    required this.assignedRole,
    required this.reportedAt,
    this.assignedAt,
    this.fixedAt,
  });

  factory Pothole.fromJson(Map<String, dynamic> json) => Pothole(
        id: json['id'] as String,
        photoUrl: json['photo_url'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        status: json['status'] as String,
        riskScore: json['risk_score'] as int,
        riskRationale: json['risk_rationale'] as String,
        roadType: json['road_type'] as String,
        assignedRole: json['assigned_role'] as String,
        reportedAt: DateTime.parse(json['reported_at'] as String),
        assignedAt: json['assigned_at'] == null ? null : DateTime.parse(json['assigned_at'] as String),
        fixedAt: json['fixed_at'] == null ? null : DateTime.parse(json['fixed_at'] as String),
      );

  final String id;
  final String photoUrl;
  final double lat;
  final double lng;
  final String status; // not_assigned | assigned | fixed
  final int riskScore;
  final String riskRationale;
  final String roadType; // highway_expressway | federal_route | state_route | municipal_local
  final String assignedRole;
  final DateTime reportedAt;
  final DateTime? assignedAt;
  final DateTime? fixedAt;
}

const roadTypeLabels = {
  'highway_expressway': 'Expressway',
  'federal_route': 'Federal Route',
  'state_route': 'State Route',
  'municipal_local': 'Municipal / Local Road',
};

const roleLabels = {
  'jkr_malaysia': 'JKR Malaysia',
  'jkr_selangor': 'JKR Selangor',
  'local_council': 'Local Council',
  'highway_concessionaire': 'Highway Concessionaire',
};

String formatOpenFor(DateTime reportedAt) {
  final d = DateTime.now().difference(reportedAt);
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m ${s}s';
  return '${s}s';
}
