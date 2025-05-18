import 'package:flutter/material.dart';

class PetWalking {
  final String id;
  final String userId;
  final String? walkerId;
  final String petId;
  final String petName;
  final DateTime walkDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double duration; // in hours
  final String location;
  final String notes;
  final double price;
  final String status; // pending, confirmed, completed, cancelled
  final String? walkerName;
  final String? walkerImage;
  final double? walkerRating;
  final DateTime createdAt;

  PetWalking({
    required this.id,
    required this.userId,
    this.walkerId,
    required this.petId,
    required this.petName,
    required this.walkDate,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.location,
    required this.notes,
    required this.price,
    required this.status,
    this.walkerName,
    this.walkerImage,
    this.walkerRating,
    required this.createdAt,
  });

  // Convert TimeOfDay to String for storage
  static String timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Convert String to TimeOfDay
  static TimeOfDay stringToTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  factory PetWalking.fromJson(Map<String, dynamic> json) {
    return PetWalking(
      id: json['id'],
      userId: json['user_id'],
      walkerId: json['walker_id'],
      petId: json['pet_id'],
      petName: json['pet_name'],
      walkDate: DateTime.parse(json['walk_date']),
      startTime: stringToTimeOfDay(json['start_time']),
      endTime: stringToTimeOfDay(json['end_time']),
      duration: json['duration'].toDouble(),
      location: json['location'],
      notes: json['notes'] ?? '',
      price: json['price'].toDouble(),
      status: json['status'],
      walkerName: json['walker_name'],
      walkerImage: json['walker_image'],
      walkerRating: json['walker_rating']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'walker_id': walkerId,
      'pet_id': petId,
      'pet_name': petName,
      'walk_date': walkDate.toIso8601String(),
      'start_time': timeOfDayToString(startTime),
      'end_time': timeOfDayToString(endTime),
      'duration': duration,
      'location': location,
      'notes': notes,
      'price': price,
      'status': status,
      'walker_name': walkerName,
      'walker_image': walkerImage,
      'walker_rating': walkerRating,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create a copy of the object with updated fields
  PetWalking copyWith({
    String? id,
    String? userId,
    String? walkerId,
    String? petId,
    String? petName,
    DateTime? walkDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    double? duration,
    String? location,
    String? notes,
    double? price,
    String? status,
    String? walkerName,
    String? walkerImage,
    double? walkerRating,
    DateTime? createdAt,
  }) {
    return PetWalking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walkerId: walkerId ?? this.walkerId,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      walkDate: walkDate ?? this.walkDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      price: price ?? this.price,
      status: status ?? this.status,
      walkerName: walkerName ?? this.walkerName,
      walkerImage: walkerImage ?? this.walkerImage,
      walkerRating: walkerRating ?? this.walkerRating,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PetWalker {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int completedWalks;
  final double hourlyRate;
  final String biography;
  final List<String> specialties;
  final bool isAvailable;

  PetWalker({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.completedWalks,
    required this.hourlyRate,
    required this.biography,
    required this.specialties,
    required this.isAvailable,
  });

  factory PetWalker.fromJson(Map<String, dynamic> json) {
    return PetWalker(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
      rating: json['rating'].toDouble(),
      completedWalks: json['completed_walks'],
      hourlyRate: json['hourly_rate'].toDouble(),
      biography: json['biography'],
      specialties: List<String>.from(json['specialties']),
      isAvailable: json['is_available'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'rating': rating,
      'completed_walks': completedWalks,
      'hourly_rate': hourlyRate,
      'biography': biography,
      'specialties': specialties,
      'is_available': isAvailable,
    };
  }
}
