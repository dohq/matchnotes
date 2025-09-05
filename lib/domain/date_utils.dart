/// Date/time helpers
DateTime truncateWithCutoff(DateTime dt, int cutoffHour) {
  // システムローカル時間で cutoffHour を跨ぐまでを "同一日" とみなす
  // 例: cutoff=4 の場合、04:00 までは前日扱い
  final shifted = dt.subtract(Duration(hours: cutoffHour));
  final dayOnly = DateTime(shifted.year, shifted.month, shifted.day);
  // キーとしては dayOnly を使う（DB保存や集計側で toYyyymmdd(dayOnly)）
  return dayOnly;
}

/// Cutoff specified in total minutes (0-1439).
DateTime truncateWithCutoffMinutes(DateTime dt, int cutoffMinutes) {
  final m = cutoffMinutes.clamp(0, (24 * 60) - 1);
  final shifted = dt.subtract(Duration(minutes: m));
  final dayOnly = DateTime(shifted.year, shifted.month, shifted.day);
  return dayOnly;
}
