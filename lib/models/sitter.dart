/// Un pet sitter, ses services, ses avis.
library;

import 'package:flutter/widgets.dart';

import 'species.dart';

class Review {
  final String author;
  final String petLine;
  final String date;
  final int rating;
  final String text;
  const Review(this.author, this.petLine, this.date, this.rating, this.text);
}

class SitterService {
  final String name;
  final String detail;
  final int price;
  final String unit;
  final ServiceType type;
  const SitterService(this.type, this.name, this.detail, this.price, this.unit);
}

class Sitter {
  final String id;
  final String firstName;
  final String lastInitial;
  final String area;
  final String city;
  final double distanceKm;
  final String photo;
  final List<String> homePhotos;
  final List<Species> species;
  final List<SitterService> services;
  final ServiceType mainService;
  final int yearsExperience;
  final String bio;
  final List<String> experience;
  final List<String> homeFacts;
  final List<String> verifications;
  final double? rating;
  final List<Review> reviews;
  final int reviewCount;
  final String responseTime;
  final Offset mapPos; // position relative sur la carte stylisée (0..1)

  const Sitter({
    required this.id,
    required this.firstName,
    required this.lastInitial,
    required this.area,
    required this.city,
    required this.distanceKm,
    required this.photo,
    required this.homePhotos,
    required this.species,
    required this.services,
    required this.mainService,
    required this.yearsExperience,
    required this.bio,
    required this.experience,
    required this.homeFacts,
    this.verifications = const [],
    this.rating,
    this.reviews = const [],
    this.reviewCount = 0,
    required this.responseTime,
    required this.mapPos,
  });

  SitterService get mainOffer => services.firstWhere((s) => s.type == mainService);
  bool get hasReviews => reviews.isNotEmpty && rating != null;
}
