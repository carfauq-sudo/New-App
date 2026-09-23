// A vehicle registered in the app. Placeholder data for now: exactly one
// entry, the user's own truck. The "Current Vehicle" picker in Settings is
// built to support more than one, but there's nothing else to switch to yet
// — a second vehicle is planned but not added.
//
// NOTE: only the *name shown on the Home header* and the Settings picker read
// this today. The 3D model, the reference data (assets/data/toyota_tacoma_
// 2026.json), the maintenance logs and the calendar are still specific to
// this one truck and are not yet split per-vehicle — that's a bigger change
// for whenever a second vehicle is actually added, not something to build
// ahead of time for a single-vehicle app.

import 'package:flutter/material.dart';

class Vehicle {
  final String id;
  final int year;
  final String make;
  final String model;
  final String trim;
  // Same photo shown on the Home page header, reused for this vehicle
  // wherever a picture (not just an icon) makes more sense — e.g. the
  // Current Vehicle picker.
  final String imagePath;
  // Generic icon, used in smaller/list spots where a photo doesn't fit well
  // (e.g. the Settings row that opens the picker).
  final IconData icon;

  // Editable in the per-vehicle settings page. Empty until the user fills
  // them in — nothing invented here.
  final String licensePlate;
  final String color;
  final String notes; // catch-all for anything else worth recording

  const Vehicle({
    required this.id,
    required this.year,
    required this.make,
    required this.model,
    required this.trim,
    required this.imagePath,
    this.icon = Icons.directions_car,
    this.licensePlate = '',
    this.color = '',
    this.notes = '',
  });

  String get displayName => '$year $make $model $trim';

  Vehicle copyWith({
    int? year,
    String? make,
    String? model,
    String? trim,
    String? licensePlate,
    String? color,
    String? notes,
  }) {
    return Vehicle(
      id: id,
      year: year ?? this.year,
      make: make ?? this.make,
      model: model ?? this.model,
      trim: trim ?? this.trim,
      imagePath: imagePath,
      icon: icon,
      licensePlate: licensePlate ?? this.licensePlate,
      color: color ?? this.color,
      notes: notes ?? this.notes,
    );
  }
}

// The only vehicle registered right now.
const _tacoma = Vehicle(
  id: 'tacoma_2026_sr5',
  year: 2026,
  make: 'Toyota',
  model: 'Tacoma',
  trim: 'SR5',
  imagePath: 'assets/images/tacoma.png',
);

// Every vehicle registered on the account. Placeholder: just the one truck.
// AppState keeps its own mutable copy of this list (see vehiclesList /
// updateVehicle), so edits made in the per-vehicle settings page don't try to
// mutate this const list.
const vehicles = <Vehicle>[_tacoma];
