import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart' as xml;
import '../constant/appconstants.dart';
import 'xml_api_client.dart';

class TonightService {
  final XmlApiClient _client;

  TonightService({XmlApiClient? client})
      : _client = client ?? XmlApiClient(baseUrl: AppConstants.baseUrl);

  static const String namespace = AppConstants.tempuriNamespace;

  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// SOAP InsertTonight request
  Future<Map<String, dynamic>> insertTonight({
    required String planning,
    required String description,
    required String location,
    required String imageBase64,
    required String date,
    required String time,
    required String email,
  }) async {
    final String cleanPlanning = _escapeXml(planning);
    final String cleanDesc = _escapeXml(description);
    final String cleanLoc = _escapeXml(location);
    final String cleanImg = _escapeXml(imageBase64);
    final String cleanDate = _escapeXml(date);
    final String cleanTime = _escapeXml(time);
    final String cleanEmail = _escapeXml(email);

    final String xmlBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <InsertTonight xmlns="$namespace">
      <Planning>$cleanPlanning</Planning>
      <Description>$cleanDesc</Description>
      <Location>$cleanLoc</Location>
      <Image>$cleanImg</Image>
      <Date>$cleanDate</Date>
      <Time>$cleanTime</Time>
      <Email>$cleanEmail</Email>
    </InsertTonight>
  </soap:Body>
</soap:Envelope>'''.trim();

    final response = await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}InsertTonight"',
      },
    );

    if (response.statusCode == 200) {
      final body = response.body.trim();

      // 1. Direct JSON check
      try {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(body);
        if (jsonMatch != null) {
          final decoded = jsonDecode(jsonMatch.group(0)!);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          } else if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        }
      } catch (e) {
        debugPrint("Direct JSON parse error: $e");
      }

      // 2. XML SOAP result element check
      try {
        if (body.contains("<")) {
          final doc = xml.XmlDocument.parse(body);
          final resultEl = doc.findAllElements('InsertTonightResult');
          if (resultEl.isNotEmpty) {
            final inner = resultEl.first.innerText.trim();
            final decoded = jsonDecode(inner);
            if (decoded is Map<String, dynamic>) {
              return decoded;
            } else if (decoded is Map) {
              return Map<String, dynamic>.from(decoded);
            }
          }
        }
      } catch (e) {
        debugPrint("XML doc parse error: $e");
      }

      return {"Status": 1, "Message": "Tonight created successfully!"};
    } else {
      throw Exception("Server returned status: ${response.statusCode}");
    }
  }

  /// SOAP ShowTonight request
  Future<List<Map<String, dynamic>>> showTonight({
    required String email,
    required double radius,
    required String planning,
  }) async {
    final String cleanEmail = _escapeXml(email);
    final String cleanPlanning = planning == "All" ? "" : _escapeXml(planning);

    final String xmlBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <ShowTonight xmlns="$namespace">
      <Email>$cleanEmail</Email>
      <Radius>$radius</Radius>
      <Planning>$cleanPlanning</Planning>
    </ShowTonight>
  </soap:Body>
</soap:Envelope>'''.trim();

    final response = await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}ShowTonight"',
      },
    );

    if (response.statusCode == 200) {
      final body = response.body.trim();

      // 1. Direct JSON check
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
        debugPrint("Direct JSON parse error in ShowTonight: $e");
      }

      // 2. XML SOAP result element check
      try {
        if (body.contains("<")) {
          final doc = xml.XmlDocument.parse(body);
          final resultEl = doc.findAllElements('ShowTonightResult');
          if (resultEl.isNotEmpty) {
            final inner = resultEl.first.innerText.trim();
            final decoded = jsonDecode(inner);
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
        }
      } catch (e) {
        debugPrint("XML doc parse error in ShowTonight: $e");
      }

      return [];
    } else {
      throw Exception("Server returned status: ${response.statusCode}");
    }
  }
}
