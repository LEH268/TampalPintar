class SevenPick {
  const SevenPick(this.epochsMs, this.immediateIndex);
  final List<int> epochsMs;
  final int immediateIndex;
}

/// Picks the 7-photo evidence window around the wake moment:
/// newest photo <= wake+slack is "immediate", plus up to 3 before / 3 after.
SevenPick? pickSeven(List<int> epochsMsAsc, int wakeMs, {int slackMs = 300}) {
  final cutoff = wakeMs + slackMs;
  var immediate = -1;
  for (var i = 0; i < epochsMsAsc.length; i++) {
    if (epochsMsAsc[i] <= cutoff) immediate = i;
  }
  if (immediate == -1) return null;
  final start = immediate - 3 < 0 ? 0 : immediate - 3;
  final end = immediate + 3 >= epochsMsAsc.length
      ? epochsMsAsc.length - 1
      : immediate + 3;
  return SevenPick(epochsMsAsc.sublist(start, end + 1), immediate - start);
}
