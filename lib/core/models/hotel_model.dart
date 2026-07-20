class HotelModel {
  final int? id;
  final String name;
  final String? description;
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final double pricePerNight;
  final int totalRooms;
  final List<int>? amenities;
  final String? primaryImage;

  HotelModel({
    this.id,
    required this.name,
    this.description,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.pricePerNight,
    required this.totalRooms,
    this.amenities,
    this.primaryImage,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    return HotelModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      pricePerNight: double.tryParse(json['price_per_night']?.toString() ?? '0') ?? 0.0,
      totalRooms: json['total_rooms'] ?? 1,
      amenities: json['amenities'] != null ? List<int>.from(json['amenities'].map((x) => x is int ? x : (x['id'] ?? x))) : null,
      primaryImage: json['primary_image'] != null ? json['primary_image']['image_path'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'price_per_night': pricePerNight,
      'total_rooms': totalRooms,
      if (amenities != null) 'amenities': amenities,
    };
  }
}
