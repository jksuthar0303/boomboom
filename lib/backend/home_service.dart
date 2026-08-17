import 'xml_api_client.dart';
import '../constant/appconstants.dart';

class HomeService {
  final XmlApiClient _client;

  HomeService({XmlApiClient? client})
      : _client = client ?? XmlApiClient(baseUrl: AppConstants.baseUrl);

  static const String namespace = AppConstants.tempuriNamespace;

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
}
