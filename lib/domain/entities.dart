class Game {
  final String id; // UUID or ULID
  final String name;
  final DateTime createdAt;
  const Game({required this.id, required this.name, required this.createdAt});
}

class Character {
  final String id; // UUID
  final String gameId;
  final String name;
  final int? colorArgb; // optional ARGB color for UI
  const Character({
    required this.id,
    required this.gameId,
    required this.name,
    this.colorArgb,
  });
}

class DailyCharacterRecordId {
  final String gameId;
  final String characterId;
  final DateTime date; // day precision
  const DailyCharacterRecordId({
    required this.gameId,
    required this.characterId,
    required this.date,
  });

  @override
  bool operator ==(Object other) {
    return other is DailyCharacterRecordId &&
        other.gameId == gameId &&
        other.characterId == characterId &&
        _isSameDay(other.date, date);
  }

  @override
  int get hashCode => Object.hash(
    gameId,
    characterId,
    DateTime(date.year, date.month, date.day).millisecondsSinceEpoch,
  );
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class DailyCharacterRecord {
  final DailyCharacterRecordId id;
  final int wins;
  final int losses;
  final String? memo;
  const DailyCharacterRecord({
    required this.id,
    required this.wins,
    required this.losses,
    this.memo,
  });

  DailyCharacterRecord copyWith({int? wins, int? losses, String? memo}) {
    return DailyCharacterRecord(
      id: id,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      memo: memo ?? this.memo,
    );
  }
}
