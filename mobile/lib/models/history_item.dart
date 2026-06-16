class HistoryItem {

  final int historyId;
  final String birdId;
  final String name;
  final String imageUrl;
  final double confidence;
  final String predictedAt;

  const HistoryItem({
    required this.historyId,
    required this.birdId,
    required this.name,
    required this.imageUrl,
    required this.confidence,
    required this.predictedAt,
  });

  factory HistoryItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return HistoryItem(
      historyId:
          json["history_id"] as int,
      birdId:
          json["bird_id"],
      name:
          json["name"],
      imageUrl:
          json["image_url"] ?? "",
      confidence:
          (json["confidence"] as num)
              .toDouble(),
      predictedAt:
          json["predicted_at"]
              .toString(),
    );
  }
}