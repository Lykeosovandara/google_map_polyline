import 'package:dio/dio.dart';
import 'package:google_map_polyline/src/route_mode.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_map_polyline/src/polyline_request.dart';

class PolylineUtils {
  PolylineRequestData _data;
  PolylineUtils(this._data);

  Future<DirectionData> getCoordinates() async {
    DirectionData data = DirectionData();

    var qParam = {
      'mode': getMode(_data.mode),
      'key': _data.apiKey,
    };

    if (_data.locationText) {
      qParam['origin'] = _data.originText;
      qParam['destination'] = _data.destinationText;
    } else {
      qParam['origin'] =
          "${_data.originLoc.latitude},${_data.originLoc.longitude}";
      qParam['destination'] =
          "${_data.destinationLoc.latitude},${_data.destinationLoc.longitude}";
    }

    Response _response;
    Dio _dio = new Dio();
    _response = await _dio.get(
        "https://maps.googleapis.com/maps/api/directions/json",
        queryParameters: qParam);

    try {
      if (_response.statusCode == 200) {
        data.coordinates = decodeEncodedPolyline(
            _response.data['routes'][0]['overview_polyline']['points']);
      }
      data.distanceText =
          _response.data['routes'][0]['legs'][0]['distance']['text'];
      data.distanceValue =
          _response.data['routes'][0]['legs'][0]['distance']['value'];
      data.startAddress =
          _response.data['routes'][0]['legs'][0]['start_address'];
      data.endAddress = _response.data['routes'][0]['legs'][0]['end_address'];
      data.durationValue =
          _response.data['routes'][0]['legs'][0]['duration']['value'];
      data.durationText =
          _response.data['routes'][0]['legs'][0]['duration']['text'];
    } catch (e) {
      print('error!!!!');
    }

    return data;
  }

  List<LatLng> decodeEncodedPolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      LatLng p = new LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }

  String getMode(RouteMode _mode) {
    switch (_mode) {
      case RouteMode.driving:
        return 'driving';
      case RouteMode.walking:
        return 'walking';
      case RouteMode.bicycling:
        return 'bicycling';
      default:
        return null;
    }
  }
}

class DirectionData {
  List<LatLng> coordinates;
  String distanceText;
  int distanceValue;
  String durationText;
  int durationValue;
  String endAddress;
  String startAddress;

  DirectionData(
      {this.coordinates,
      this.distanceText,
      this.distanceValue,
      this.startAddress,
      this.endAddress,
      this.durationText,
      this.durationValue});
}
