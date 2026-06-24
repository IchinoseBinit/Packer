import 'package:flutter/material.dart';

enum RipenessCategoryEnum {
  raw("raw", "Raw (काँचो)", Icons.ac_unit),
  ripe("ripe", "Ripe (पाकेको)", Icons.check_circle);

  final String name;
  final String value;
  final IconData icon;

  const RipenessCategoryEnum(this.value, this.name, this.icon);
}
