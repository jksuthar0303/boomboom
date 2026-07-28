import 'package:xml/xml.dart' as xml;
import 'xml_api_client.dart';
import '../model/travel_user.dart';

class CrudExampleService {
  final XmlApiClient _client;

  // Initialize with your actual .NET ASMX/WCF endpoint or REST base URL
  CrudExampleService({XmlApiClient? client})
      : _client = client ?? XmlApiClient(baseUrl: 'https://example.com/api/TravelService.asmx');

  static const String namespace = 'http://tempuri.org/';

  /// 1. READ ALL (Fetch all travel users)
  Future<List<TravelUser>> getTravelUsers() async {
    const String method = 'GetTravelUsers';
    final methodBody = '<$method xmlns="$namespace" />';

    final response = await _client.postSoap(
      endpoint: '',
      soapAction: method,
      methodBody: methodBody,
      xmlns: namespace,
    );

    // Parse the XML response
    final document = xml.XmlDocument.parse(response.body);
    
    // .NET SOAP service typically wraps result under MethodNameResult or MethodNameResponse
    final userElements = document.findAllElements('TravelUser');
    
    return userElements.map((element) => TravelUser.fromXml(element)).toList();
  }

  /// 2. CREATE (Add a new travel user)
  Future<TravelUser> createTravelUser(TravelUser user) async {
    const String method = 'CreateTravelUser';
    final methodBody = '''
      <$method xmlns="$namespace">
        <user>
          ${user.toXmlSnippet()}
        </user>
      </$method>
    '''.trim();

    final response = await _client.postSoap(
      endpoint: '',
      soapAction: method,
      methodBody: methodBody,
      xmlns: namespace,
    );

    final document = xml.XmlDocument.parse(response.body);
    final userElements = document.findAllElements('TravelUser');
    if (userElements.isNotEmpty) {
      return TravelUser.fromXml(userElements.first);
    }
    return user; // Return the local model if response parses to empty but success
  }

  /// 3. UPDATE (Edit an existing travel user)
  Future<bool> updateTravelUser(TravelUser user) async {
    const String method = 'UpdateTravelUser';
    final methodBody = '''
      <$method xmlns="$namespace">
        <user>
          ${user.toXmlSnippet()}
        </user>
      </$method>
    '''.trim();

    final response = await _client.postSoap(
      endpoint: '',
      soapAction: method,
      methodBody: methodBody,
      xmlns: namespace,
    );

    final document = xml.XmlDocument.parse(response.body);
    
    // .NET SOAP methods usually return a boolean or status string for updates
    final resultElement = document.findAllElements('${method}Result');
    if (resultElement.isNotEmpty) {
      return resultElement.first.innerText.toLowerCase() == 'true';
    }
    
    return response.statusCode == 200; // fallback success check
  }

  /// 4. DELETE (Remove a travel user by ID)
  Future<bool> deleteTravelUser(String id) async {
    const String method = 'DeleteTravelUser';
    final methodBody = '''
      <$method xmlns="$namespace">
        <id>$id</id>
      </$method>
    '''.trim();

    final response = await _client.postSoap(
      endpoint: '',
      soapAction: method,
      methodBody: methodBody,
      xmlns: namespace,
    );

    final document = xml.XmlDocument.parse(response.body);
    final resultElement = document.findAllElements('${method}Result');
    if (resultElement.isNotEmpty) {
      return resultElement.first.innerText.toLowerCase() == 'true';
    }
    
    return response.statusCode == 200;
  }
}
