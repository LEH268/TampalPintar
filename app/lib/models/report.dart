class PinSummary {
  const PinSummary(this.id, this.lat, this.lng);
  final String id;
  final double lat;
  final double lng;
  Map<String, dynamic> toJson() => {'id': id, 'lat': lat, 'lng': lng};
}

class ReportDetails {
  ReportDetails(Map<String, dynamic> row)
      : id = row['id'],
        lat = (row['lat'] as num).toDouble(),
        lng = (row['lng'] as num).toDouble(),
        reportedAt = DateTime.parse(row['reported_at']).toLocal(),
        status = row['status'],
        source = row['source'],
        speedKmh = (row['speed_kmh'] as num?)?.toDouble(),
        riskScore = row['risk_score'],
        roadType = row['road_type'],
        authorityName = row['authority_name'],
        authorityRole = row['authority_role'],
        rationale = row['rationale'],
        assigned = row['assigned'] ?? false,
        mediaPaths = [...(row['media_paths'] as List? ?? []).cast<String>()],
        immediateIndex = row['immediate_index'];

  final String id;
  final double lat, lng;
  final DateTime reportedAt;
  final String status, source;
  final double? speedKmh;
  final int? riskScore;
  final String? roadType, authorityName, authorityRole, rationale;
  final bool assigned;
  final List<String> mediaPaths;
  final int? immediateIndex;

  String? get immediatePath {
    if (mediaPaths.isEmpty) return null;
    final i = immediateIndex ?? 0;
    return mediaPaths[i >= 0 && i < mediaPaths.length ? i : 0];
  }
}

const kRoadTypeLabels = {
  'highway_expressway': 'Highway/Expressway',
  'federal_route': 'Federal Route',
  'state_route': 'State Route',
  'municipal_local': 'Municipal/Local Road',
};
