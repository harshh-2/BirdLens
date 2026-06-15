class Bird {
  final String id;
  final String name;
  final String scientificName;
  final String description;
  final String habitat;
  final String conservationStatus;
  final String imageUrl;

  const Bird({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.description,
    required this.habitat,
    required this.conservationStatus,
    required this.imageUrl,
  });

  factory Bird.fromJson(Map<String,dynamic> json){
    return Bird(
      id: json['id'],
      name: json['name'],
      scientificName:
          json['scientific_name'] ?? '',
      description:
          json['description'] ?? '',
      habitat:
          json['habitat'] ?? '',
      conservationStatus:
          json['conservation_status'] ?? '',
      imageUrl:
          json['image_url'] ?? '',
    );
  }
}