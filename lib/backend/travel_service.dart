import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart' as xml;
import 'xml_api_client.dart';
import '../constant/appconstants.dart';

class TravelService {
  final XmlApiClient _client;

  TravelService({XmlApiClient? client})
      : _client = client ?? XmlApiClient(baseUrl: AppConstants.baseUrl);

  static const String namespace = AppConstants.tempuriNamespace;

  /// SOAP InsertTravel request
  Future<XmlResponse> insertTravel({
    required String journeyType,
    required String travelStyle,
    required String travelCompanion,
    required String isHide,
    required String fromCountry,
    required String fromCity,
    required String toCountry,
    required String toCity,
    required String fromDate,
    required String toDate,
    required String description,
    required String email,
  }) async {
    final String cleanDesc = _escapeXml(description);
    final String cleanJourneyType = _escapeXml(journeyType);
    final String cleanTravelStyle = _escapeXml(travelStyle);
    final String cleanCompanion = _escapeXml(travelCompanion);
    final String cleanFromCountry = _escapeXml(fromCountry);
    final String cleanFromCity = _escapeXml(fromCity);
    final String cleanToCountry = _escapeXml(toCountry);
    final String cleanToCity = _escapeXml(toCity);
    final String cleanFromDate = _escapeXml(fromDate);
    final String cleanToDate = _escapeXml(toDate);
    final String cleanEmail = _escapeXml(email);
    final String cleanIsHide = _escapeXml(isHide);

    final String xmlBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <InsertTravel xmlns="$namespace">
      <JourneyType>$cleanJourneyType</JourneyType>
      <TravelStyle>$cleanTravelStyle</TravelStyle>
      <TravelCompanion>$cleanCompanion</TravelCompanion>
      <ishide>$cleanIsHide</ishide>
      <FromCountry>$cleanFromCountry</FromCountry>
      <FromCity>$cleanFromCity</FromCity>
      <ToCountry>$cleanToCountry</ToCountry>
      <ToCity>$cleanToCity</ToCity>
      <FromDate>$cleanFromDate</FromDate>
      <ToDate>$cleanToDate</ToDate>
      <Description>$cleanDesc</Description>
      <Email>$cleanEmail</Email>
    </InsertTravel>
  </soap:Body>
</soap:Envelope>'''.trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}InsertTravel"',
      },
    );
  }

  /// SOAP ShowTravelByEmail request
  Future<List<Map<String, dynamic>>> showTravelByEmail({
    required String email,
  }) async {
    final String cleanEmail = _escapeXml(email);
    final String xmlBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <ShowTravelByEmail xmlns="$namespace">
      <Email>$cleanEmail</Email>
    </ShowTravelByEmail>
  </soap:Body>
</soap:Envelope>'''.trim();

    final response = await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}ShowTravelByEmail"',
      },
    );

    if (response.statusCode == 200) {
      final body = response.body.trim();

      // 1. Check direct JSON in body (e.g. {"Status": 1, "Data": [...]})
      try {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(body);
        if (jsonMatch != null) {
          final decoded = jsonDecode(jsonMatch.group(0)!);
          if (decoded is Map && decoded["Data"] is List) {
            return List<Map<String, dynamic>>.from(
              (decoded["Data"] as List).map((e) => Map<String, dynamic>.from(e)),
            );
          } else if (decoded is List) {
            return List<Map<String, dynamic>>.from(
              decoded.map((e) => Map<String, dynamic>.from(e)),
            );
          }
        }
      } catch (e) {
        debugPrint("Direct JSON parse in ShowTravelByEmail: $e");
      }

      // 2. Check XML SOAP result element
      try {
        if (body.contains("<")) {
          final doc = xml.XmlDocument.parse(body);
          final resultEl = doc.findAllElements('ShowTravelByEmailResult');
          if (resultEl.isNotEmpty) {
            final innerJson = resultEl.first.innerText.trim();
            final decoded = jsonDecode(innerJson);
            if (decoded is Map && decoded["Data"] is List) {
              return List<Map<String, dynamic>>.from(
                (decoded["Data"] as List).map((e) => Map<String, dynamic>.from(e)),
              );
            }
          }
        }
      } catch (e) {
        debugPrint("XML doc parse in ShowTravelByEmail: $e");
      }

      return [];
    } else {
      throw Exception("Server returned status: ${response.statusCode}");
    }
  }

  /// SOAP ShowUpcomingTrips request
  Future<List<Map<String, dynamic>>> showUpcomingTrips() async {
    final String xmlBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <ShowUpcomingTrips xmlns="$namespace" />
  </soap:Body>
</soap:Envelope>'''.trim();

    final response = await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}ShowUpcomingTrips"',
      },
    );

    if (response.statusCode == 200) {
      final body = response.body.trim();

      // 1. Check direct JSON in body (e.g. {"Status": 1, "Data": [...]})
      try {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(body);
        if (jsonMatch != null) {
          final decoded = jsonDecode(jsonMatch.group(0)!);
          if (decoded is Map && decoded["Data"] is List) {
            return List<Map<String, dynamic>>.from(
              (decoded["Data"] as List).map((e) => Map<String, dynamic>.from(e)),
            );
          } else if (decoded is List) {
            return List<Map<String, dynamic>>.from(
              decoded.map((e) => Map<String, dynamic>.from(e)),
            );
          }
        }
      } catch (e) {
        debugPrint("Direct JSON parse in ShowUpcomingTrips: $e");
      }

      // 2. Check XML SOAP result element
      try {
        if (body.contains("<")) {
          final doc = xml.XmlDocument.parse(body);
          final resultEl = doc.findAllElements('ShowUpcomingTripsResult');
          if (resultEl.isNotEmpty) {
            final innerJson = resultEl.first.innerText.trim();
            final decoded = jsonDecode(innerJson);
            if (decoded is Map && decoded["Data"] is List) {
              return List<Map<String, dynamic>>.from(
                (decoded["Data"] as List).map((e) => Map<String, dynamic>.from(e)),
              );
            }
          }
        }
      } catch (e) {
        debugPrint("XML doc parse in ShowUpcomingTrips: $e");
      }

      return [];
    } else {
      throw Exception("Server returned status: ${response.statusCode}");
    }
  }

  /// SOAP DeleteTravel request
  Future<XmlResponse> deleteTravel({
    required int id,
    required String email,
  }) async {
    final String cleanEmail = _escapeXml(email);
    final String xmlBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <DeleteTravel xmlns="$namespace">
      <id>$id</id>
      <Email>$cleanEmail</Email>
    </DeleteTravel>
  </soap:Body>
</soap:Envelope>'''.trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}DeleteTravel"',
      },
    );
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
