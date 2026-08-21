import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart' as xml;
import 'xml_api_client.dart';
import '../constant/appconstants.dart';

class HomeService {
  final XmlApiClient _client;

  HomeService({XmlApiClient? client})
      : _client = client ?? XmlApiClient(baseUrl: AppConstants.baseUrl);

  static const String namespace = AppConstants.tempuriNamespace;

  /// SOAP ShowSettingsByEmail request.
  /// The service returns an XML response whose inner text is JSON.
  Future<XmlResponse> showSettingsByEmail({
    required String email,
    String? token,
  }) async {
    final cleanEmail = _escapeXml(email);
    final xmlBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <ShowSettingsByEmail xmlns="$namespace">
      <token>${token ?? AppConstants.dummyToken}</token>
      <Email>$cleanEmail</Email>
    </ShowSettingsByEmail>
  </soap:Body>
</soap:Envelope>'''.trim();

    return _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}ShowSettingsByEmail"',
      },
    );
  }

  String _escapeXml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  /// SOAP UpdateSettings request.
  Future<XmlResponse> updateSettings({
    required String type,
    required bool mode,
    required String email,
    String? token,
  }) async {
    final xmlBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <UpdateSettings xmlns="$namespace">
      <token>${_escapeXml(token ?? AppConstants.dummyToken)}</token>
      <Type>${_escapeXml(type)}</Type>
      <Mode>${mode ? 'true' : 'false'}</Mode>
      <Email>${_escapeXml(email)}</Email>
    </UpdateSettings>
  </soap:Body>
</soap:Envelope>'''.trim();

    return _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}UpdateSettings"',
      },
    );
  }

  /// SOAP FavoriteLikeView_Insert request.
  Future<XmlResponse> favoriteLikeViewInsert({
    required String myEmail,
    required String actionEmail,
    required String action,
    String? token,
  }) async {
    final String xmlBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <FavoriteLikeView_Insert xmlns="$namespace">
      <token>${token ?? AppConstants.dummyToken}</token>
      <myEmail>$myEmail</myEmail>
      <actionEmail>$actionEmail</actionEmail>
      <action>$action</action>
    </FavoriteLikeView_Insert>
  </soap:Body>
</soap:Envelope>'''.trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}FavoriteLikeView_Insert"',
      },
    );
  }

  /// Returns favourite/like/view rows for the logged-in user.
  Future<XmlResponse> favoriteLikeViewShowByMyEmail({
    required String myEmail,
    required String action,
    String? token,
  }) async {
    final String xmlBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <FavoriteLikeView_ShowByMyEmail xmlns="$namespace">
      <token>${token ?? AppConstants.dummyToken}</token>
      <myEmail>$myEmail</myEmail>
      <action>$action</action>
    </FavoriteLikeView_ShowByMyEmail>
  </soap:Body>
</soap:Envelope>'''.trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}FavoriteLikeView_ShowByMyEmail"',
      },
    );
  }

  /// Returns users who performed an action on the supplied email.
  Future<XmlResponse> favoriteLikeViewShowByActionEmail({
    required String actionEmail,
    required String action,
    String? token,
  }) async {
    final String xmlBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <FavoriteLikeView_ShowByActionEmail xmlns="$namespace">
      <token>${token ?? AppConstants.dummyToken}</token>
      <actionEmail>$actionEmail</actionEmail>
      <action>$action</action>
    </FavoriteLikeView_ShowByActionEmail>
  </soap:Body>
</soap:Envelope>'''.trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}FavoriteLikeView_ShowByActionEmail"',
      },
    );
  }

  /// SOAP ShowAllExceptMe request (Everyone & New Matches)
  Future<XmlResponse> showAllExceptMe({required String myEmail}) async {
    final String xmlBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <ShowAllExceptMe xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <MyEmail>$myEmail</MyEmail>
    </ShowAllExceptMe>
  </soap:Body>
</soap:Envelope>'''.trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}ShowAllExceptMe"',
      },
    );
  }

  /// SOAP ShowOnlineUsers request (Active Profiles tab)
  Future<XmlResponse> showOnlineUsers({required String myEmail}) async {
    final String xmlBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <ShowOnlineUsers xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <MyEmail>$myEmail</MyEmail>
    </ShowOnlineUsers>
  </soap:Body>
</soap:Envelope>'''.trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}ShowOnlineUsers"',
      },
    );
  }

  /// SOAP ShowVerifiedUsers request (Verified Profiles tab)
  Future<XmlResponse> showVerifiedUsers({required String myEmail}) async {
    final String xmlBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <ShowVerifiedUsers xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <MyEmail>$myEmail</MyEmail>
    </ShowVerifiedUsers>
  </soap:Body>
</soap:Envelope>'''.trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}ShowVerifiedUsers"',
      },
    );
  }

  /// SOAP ShowNearbyUsers request (Nearby Map Screen)
  Future<XmlResponse> showNearbyUsers({
    required String lat,
    required String lon,
    required String radius,
    String? token,
  }) async {
    final String xmlBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <ShowNearbyUsers xmlns="$namespace">
      <token>${token ?? AppConstants.dummyToken}</token>
      <lat>$lat</lat>
      <lon>$lon</lon>
      <radius>$radius</radius>
    </ShowNearbyUsers>
  </soap:Body>
</soap:Envelope>'''.trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}ShowNearbyUsers"',
      },
    );
  }

  /// SOAP ShowNearbyUsers parsed list (Nearby Map Screen)
  Future<List<Map<String, dynamic>>> getNearbyUsersList({
    required String lat,
    required String lon,
    required String radius,
    String? token,
  }) async {
    final response = await showNearbyUsers(
      lat: lat,
      lon: lon,
      radius: radius,
      token: token,
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
        debugPrint("Direct JSON parse error in ShowNearbyUsers: $e");
      }

      // 2. XML SOAP result element check
      try {
        if (body.contains("<")) {
          final doc = xml.XmlDocument.parse(body);
          final resultEl = doc.findAllElements('ShowNearbyUsersResult');
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
        debugPrint("XML doc parse error in ShowNearbyUsers: $e");
      }

      return [];
    } else {
      throw Exception("Server returned status: ${response.statusCode}");
    }
  }
}
