class UserProfile {

  final String username;
  final String email;
  final DateTime createdAt;

  final int totalScans;
  final int favorites;
  final int uniqueSpecies;

  const UserProfile({
    required this.username,
    required this.email,
    required this.createdAt,
    required this.totalScans,
    required this.favorites,
    required this.uniqueSpecies,
  });

  factory UserProfile.fromJson(
    Map<String,dynamic> json,
  ) {

    final stats =
        json["stats"];

    return UserProfile(
      username:
          json["username"],

      email:
          json["email"],

      createdAt:
          DateTime.parse(
        json["created_at"],
      ),

      totalScans:
          stats["total_scans"],

      favorites:
          stats["favorites"],

      uniqueSpecies:
          stats["unique_species"],
    );
  }
}