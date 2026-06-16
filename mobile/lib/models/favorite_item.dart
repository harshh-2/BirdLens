class FavoriteItem {

  final String birdId;
  final String name;
  final String imageUrl;
  final String habitat;
  const FavoriteItem({
    required this.birdId,
    required this.name,
    required this.imageUrl,
    required this.habitat,
  });

  factory FavoriteItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return FavoriteItem(
      birdId:
          json["bird_id"]
              .toString(),

      name:
          json["name"]
              .toString(),
      
      habitat:
          json["habitat"]
              .toString(),

      imageUrl:
          json["image_url"] ?? "",
    );
  }
}