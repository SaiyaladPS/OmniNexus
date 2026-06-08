class MapsConfig {
  MapsConfig._();

  static const String googleApiKey = 'AlzaSyAhTp7Vlijls53Es4UA0yDcGh7LvwDZACY';

  static const String tileUrl = 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';

  static String placesNearbyUrl(double lat, double lng, {int radiusMeters = 5000, String type = 'hospital'}) {
    return 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng&radius=$radiusMeters&type=$type&key=$googleApiKey';
  }

  static String staticMapUrl(double lat, double lng, {int zoom = 14, int width = 400, int height = 200}) {
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng&zoom=$zoom&size=${width}x$height&markers=color:red%7C$lat,$lng&key=$googleApiKey';
  }
}
