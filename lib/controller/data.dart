import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'dart:math';

class Parameter {
  final String id;
  final String description;
  final String type;
  final List<TimeRange> timeRanges;

  Parameter({
    required this.id,
    required this.description,
    required this.type,
    required this.timeRanges,
  });
}

class TimeRange {
  final String type;
  final String datetime;
  final String value;
  final String unit;

  TimeRange({
    required this.type,
    required this.datetime,
    required this.value,
    required this.unit,
  });
}

class Area {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<Parameter> parameters;

  Area({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.parameters,
  });
}

class ApiController {
  static const String xmlDataUrl =
      'https://data.bmkg.go.id/DataMKG/MEWS/DigitalForecast/DigitalForecast-DKIJakarta.xml';

  Future<List<Area>> fetchXmlData() async {
    final response = await http.get(Uri.parse(
        'https://data.bmkg.go.id/DataMKG/MEWS/DigitalForecast/DigitalForecast-DKIJakarta.xml'));

    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      return parseAreas(document);
    } else {
      throw Exception('Failed to load XML data');
    }
  }

  List<Area> parseAreas(XmlDocument document) {
    final areas = <Area>[];
    final areaElements = document.findAllElements('area');

    for (var areaElement in areaElements) {
      final id = areaElement.getAttribute('id') ?? '';
      final name = areaElement.findElements('name').first.text;
      final latitude =
          double.parse(areaElement.getAttribute('latitude') ?? '0');
      final longitude =
          double.parse(areaElement.getAttribute('longitude') ?? '0');
      final parameters = parseParameters(areaElement);

      areas.add(Area(
        id: id,
        name: name,
        latitude: latitude,
        longitude: longitude,
        parameters: parameters,
      ));
    }

    return areas;
  }

  List<Parameter> parseParameters(XmlElement areaElement) {
    final parameters = <Parameter>[];
    final parameterElements = areaElement.findElements('parameter');

    for (var parameterElement in parameterElements) {
      final id = parameterElement.getAttribute('id') ?? '';
      if (['hu', 't', 'weather', 'wd', 'ws'].contains(id)) {
        var description = parameterElement.getAttribute('description') ?? '';
        final type = parameterElement.getAttribute('type') ?? '';
        final timeRanges = parseTimeRanges(parameterElement);

        if (id == 'weather') {
          description =
              description.replaceAllMapped(RegExp(r'\b\d+\b'), (match) {
            switch (match.group(0)) {
              case '0':
                return 'Cerah';
              case '1':
              case '2':
                return 'Cerah Berawan';
              case '3':
                return 'Berawan';
              case '4':
                return 'Berawan Tebal';
              case '5':
                return 'Udara Kabur';
              case '10':
                return 'Asap';
              case '45':
                return 'Kabut';
              case '60':
                return 'Hujan Ringan';
              case '61':
                return 'Hujan Sedang';
              case '63':
                return 'Hujan Lebat';
              case '80':
                return 'Hujan Lokal';
              case '95':
                return 'Hujan Petir';
              case '97':
                return 'Hujan Petir';
              default:
                return match.group(0)!;
            }
          });
        }

        parameters.add(Parameter(
          id: id,
          description: description,
          type: type,
          timeRanges: timeRanges,
        ));
      }
    }

    return parameters;
  }

  List<TimeRange> parseTimeRanges(XmlElement parameterElement) {
    final timeRanges = <TimeRange>[];
    final timeRangeElements = parameterElement.findElements('timerange');

    for (var timeRangeElement in timeRangeElements) {
      final type = timeRangeElement.getAttribute('type') ?? '';
      final datetime = timeRangeElement.getAttribute('datetime') ?? '';
      final valueElement = timeRangeElement.findElements('value').first;
      final value = valueElement.text;
      final unit = valueElement.getAttribute('unit') ?? '';

      timeRanges.add(TimeRange(
        type: type,
        datetime: datetime,
        value: value,
        unit: unit,
      ));
    }

    return timeRanges;
  }

  Area findClosestArea(
      List<Area> areas, double userLatitude, double userLongitude) {
    Area? closestArea;
    double closestDistance = double.infinity;

    for (var area in areas) {
      final distance = calculateDistance(
          userLatitude, userLongitude, area.latitude, area.longitude);
      if (distance < closestDistance) {
        closestDistance = distance;
        closestArea = area;
      }
    }

    return closestArea!;
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Pi/180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  Future<String> fetchXmlDataAsString() async {
    final response = await http.get(Uri.parse(xmlDataUrl));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load XML data');
    }
  }
}
