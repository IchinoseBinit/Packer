

import 'package:galli_map/galli_map.dart';

extension MapExtension on Map {

  LatLng toLatLng() {
    final latitude = this['latitude'];
    final longitude = this['longitude'];
    return LatLng(latitude, longitude);
  }

}