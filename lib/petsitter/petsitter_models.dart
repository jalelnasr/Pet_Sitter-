import 'package:flutter/material.dart';
import 'package:pet_sitter/core/config/api_constants.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

enum SitterServiceType {
  walking,
  boarding,
  dayCare,
  homeVisit,
  grooming,
  vetTransport;

  String get label => switch (this) {
    walking => 'Promenade',
    boarding => 'Hébergement',
    dayCare => 'Garderie de jour',
    homeVisit => 'Visite à domicile',
    grooming => 'Toilettage',
    vetTransport => 'Transport vétérinaire',
  };

  IconData get icon => switch (this) {
    walking => Icons.directions_walk,
    boarding => PhosphorIconsRegular.houseLine,
    dayCare => PhosphorIconsRegular.sun,
    homeVisit => PhosphorIconsRegular.doorOpen,
    grooming => Icons.content_cut,
    vetTransport => Icons.directions_car,
  };

  String get apiValue => switch (this) {
    walking => 'WALKING',
    boarding => 'BOARDING',
    dayCare => 'DAY_CARE',
    homeVisit => 'HOME_VISIT',
    grooming => 'GROOMING',
    vetTransport => 'VET_TRANSPORT',
  };

  static SitterServiceType fromApi(String val) => switch (val.toUpperCase()) {
    'WALKING' => walking,
    'BOARDING' => boarding,
    'DAY_CARE' => dayCare,
    'HOME_VISIT' => homeVisit,
    'GROOMING' => grooming,
    'VET_TRANSPORT' => vetTransport,
    _ => boarding,
  };
}

enum PetSpeciesType {
  dog,
  cat,
  bird,
  rabbit,
  other;

  String get label => switch (this) {
    dog => 'Chien',
    cat => 'Chat',
    bird => 'Oiseau',
    rabbit => 'Lapin',
    other => 'Autre animal',
  };

  IconData get icon => switch (this) {
    dog => PhosphorIconsRegular.dog,
    cat => PhosphorIconsRegular.cat,
    bird => PhosphorIconsRegular.bird,
    rabbit => PhosphorIconsRegular.pawPrint,
    other => PhosphorIconsRegular.pawPrint,
  };

  String get apiValue => switch (this) {
    dog => 'DOG',
    cat => 'CAT',
    bird => 'BIRD',
    rabbit => 'RABBIT',
    other => 'OTHER',
  };

  static PetSpeciesType fromApi(String val) => switch (val.toUpperCase()) {
    'DOG' => dog,
    'CAT' => cat,
    'BIRD' => bird,
    'RABBIT' => rabbit,
    _ => other,
  };
}

enum PetSizeType {
  small,
  medium,
  large,
  giant;

  String get label => switch (this) {
    small => 'Petit (< 7 kg)',
    medium => 'Moyen (7 - 18 kg)',
    large => 'Grand (18 - 45 kg)',
    giant => 'Très grand (> 45 kg)',
  };

  String get apiValue => switch (this) {
    small => 'SMALL',
    medium => 'MEDIUM',
    large => 'LARGE',
    giant => 'GIANT',
  };

  static PetSizeType fromApi(String val) => switch (val.toUpperCase()) {
    'SMALL' => small,
    'MEDIUM' => medium,
    'LARGE' => large,
    'GIANT' => giant,
    _ => small,
  };
}

enum ReservationStatus {
  pending,
  accepted,
  rejected,
  cancelled,
  completed;

  String get label => switch (this) {
    pending => 'En attente',
    accepted => 'Confirmée',
    rejected => 'Refusée',
    cancelled => 'Annulée',
    completed => 'Terminée',
  };

  Color get color => switch (this) {
    pending => const Color(0xFFE5A000),
    accepted => const Color(0xFF2E7D32),
    rejected => const Color(0xFFD32F2F),
    cancelled => const Color(0xFF757575),
    completed => const Color(0xFF1976D2),
  };

  Color get backgroundColor => switch (this) {
    pending => const Color(0xFFFFF8E1),
    accepted => const Color(0xFFE8F5E9),
    rejected => const Color(0xFFFFEBEE),
    cancelled => const Color(0xFFEEEEEE),
    completed => const Color(0xFFE3F2FD),
  };

  IconData get icon => switch (this) {
    pending => PhosphorIconsRegular.clock,
    accepted => PhosphorIconsRegular.checkCircle,
    rejected => PhosphorIconsRegular.xCircle,
    cancelled => Icons.block,
    completed => Icons.emoji_events,
  };

  String get apiValue => switch (this) {
    pending => 'PENDING',
    accepted => 'ACCEPTED',
    rejected => 'REJECTED',
    cancelled => 'CANCELLED',
    completed => 'COMPLETED',
  };

  static ReservationStatus fromApi(String val) => switch (val.toUpperCase()) {
    'PENDING' => pending,
    'ACCEPTED' => accepted,
    'REJECTED' => rejected,
    'CANCELLED' => cancelled,
    'COMPLETED' => completed,
    _ => pending,
  };
}

class PetSitter {
  const PetSitter({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.bio,
    required this.governorate,
    required this.city,
    required this.address,
    required this.phone,
    required this.photoUrl,
    required this.gallery,
    required this.experienceYears,
    required this.pricePerHour,
    required this.pricePerDay,
    required this.services,
    required this.acceptedPetTypes,
    required this.acceptedSizes,
    required this.hasGarden,
    required this.hasOwnPets,
    required this.availability,
    required this.verified,
    required this.active,
    required this.averageRating,
    required this.reviewsCount,
  });

  final String id;
  final String userId;
  final String fullName;
  final String bio;
  final String governorate;
  final String city;
  final String address;
  final String phone;
  final String photoUrl;
  final List<String> gallery;
  final int experienceYears;
  final double pricePerHour;
  final double pricePerDay;
  final Set<SitterServiceType> services;
  final Set<PetSpeciesType> acceptedPetTypes;
  final Set<PetSizeType> acceptedSizes;
  final bool hasGarden;
  final bool hasOwnPets;
  final String availability;
  final bool verified;
  final bool active;
  final double averageRating;
  final int reviewsCount;

  String get resolvedPhotoUrl => ApiConstants.resolveMediaUrl(photoUrl);

  List<String> get resolvedGallery =>
      gallery.map(ApiConstants.resolveMediaUrl).toList();

  String get locationLabel => '$city, $governorate';

  factory PetSitter.fromJson(Map<String, dynamic> json) {
    final rawServices = json['services'];
    final Set<SitterServiceType> parsedServices = {};
    if (rawServices is Iterable) {
      for (final s in rawServices) {
        if (s is String) parsedServices.add(SitterServiceType.fromApi(s));
      }
    }

    final rawPets = json['acceptedPetTypes'];
    final Set<PetSpeciesType> parsedPets = {};
    if (rawPets is Iterable) {
      for (final p in rawPets) {
        if (p is String) parsedPets.add(PetSpeciesType.fromApi(p));
      }
    }

    final rawSizes = json['acceptedSizes'];
    final Set<PetSizeType> parsedSizes = {};
    if (rawSizes is Iterable) {
      for (final sz in rawSizes) {
        if (sz is String) parsedSizes.add(PetSizeType.fromApi(sz));
      }
    }

    final rawGallery = json['gallery'];
    final List<String> parsedGallery = [];
    if (rawGallery is Iterable) {
      for (final g in rawGallery) {
        if (g is String) parsedGallery.add(g);
      }
    }

    return PetSitter(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      governorate: json['governorate'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      gallery: parsedGallery,
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble() ?? 10.0,
      pricePerDay: (json['pricePerDay'] as num?)?.toDouble() ?? 35.0,
      services: parsedServices,
      acceptedPetTypes: parsedPets,
      acceptedSizes: parsedSizes,
      hasGarden: json['hasGarden'] as bool? ?? false,
      hasOwnPets: json['hasOwnPets'] as bool? ?? false,
      availability: json['availability'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class SitterReview {
  const SitterReview({
    required this.id,
    required this.sitterId,
    this.reservationId,
    required this.ownerId,
    required this.ownerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String sitterId;
  final String? reservationId;
  final String ownerId;
  final String ownerName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  factory SitterReview.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return SitterReview(
      id: json['id'] as String? ?? '',
      sitterId: json['sitterId'] as String? ?? '',
      reservationId: json['reservationId'] as String?,
      ownerId: json['ownerId'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? 'Client',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String? ?? '',
      createdAt: parsedDate,
    );
  }
}

class SitterReservation {
  const SitterReservation({
    required this.id,
    required this.sitterId,
    this.sitterName,
    this.sitterPhoto,
    this.sitterCity,
    required this.ownerId,
    this.ownerName,
    required this.petName,
    required this.petType,
    required this.petSize,
    required this.service,
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
    this.notes,
    required this.totalPrice,
    required this.status,
    this.rejectionReason,
    required this.hasReview,
    required this.createdAt,
  });

  final String id;
  final String sitterId;
  final String? sitterName;
  final String? sitterPhoto;
  final String? sitterCity;
  final String ownerId;
  final String? ownerName;
  final String petName;
  final PetSpeciesType petType;
  final PetSizeType petSize;
  final SitterServiceType service;
  final DateTime startDate;
  final DateTime endDate;
  final String? startTime;
  final String? endTime;
  final String? notes;
  final double totalPrice;
  final ReservationStatus status;
  final String? rejectionReason;
  final bool hasReview;
  final DateTime createdAt;

  String? get resolvedSitterPhoto =>
      sitterPhoto != null ? ApiConstants.resolveMediaUrl(sitterPhoto!) : null;

  int get daysCount {
    final diff = endDate.difference(startDate).inDays;
    return diff <= 0 ? 1 : diff + 1;
  }

  factory SitterReservation.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      try {
        return DateTime.parse(val as String);
      } catch (_) {
        return DateTime.now();
      }
    }

    return SitterReservation(
      id: json['id'] as String? ?? '',
      sitterId: json['sitterId'] as String? ?? '',
      sitterName: json['sitterName'] as String?,
      sitterPhoto: json['sitterPhoto'] as String?,
      sitterCity: json['sitterCity'] as String?,
      ownerId: json['ownerId'] as String? ?? '',
      ownerName: json['ownerName'] as String?,
      petName: json['petName'] as String? ?? 'Animal',
      petType: PetSpeciesType.fromApi(json['petType'] as String? ?? 'DOG'),
      petSize: PetSizeType.fromApi(json['petSize'] as String? ?? 'SMALL'),
      service: SitterServiceType.fromApi(json['service'] as String? ?? 'BOARDING'),
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      notes: json['notes'] as String?,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: ReservationStatus.fromApi(json['status'] as String? ?? 'PENDING'),
      rejectionReason: json['rejectionReason'] as String?,
      hasReview: json['hasReview'] as bool? ?? false,
      createdAt: parseDate(json['createdAt']),
    );
  }
}
