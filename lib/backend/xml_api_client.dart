import 'dart:async';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart' as xml;

/// Compatibility wrapper so existing services that check `.body` and `.statusCode` 
/// do not break when shifting from the http package to Dio.
class XmlResponse {
  final String body;
  final int statusCode;

  XmlResponse({required this.body, required this.statusCode});
}

class XmlApiClient {
  final String baseUrl;
  final Duration timeout;
  late final Dio _dio;

  XmlApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 15),
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        sendTimeout: timeout,
      ),
    );

    // 🔥 Added the Custom XML Logging Interceptor for Console Debugging
    _dio.interceptors.add(XmlLoggingInterceptor());
  }

  Future<XmlResponse> postXml({
    required String endpoint,
    required String xmlBody,
    Map<String, String>? headers,
    ProgressCallback? onSendProgress,
  }) async {
    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/xml; charset=utf-8',
      'Accept': 'application/xml',
      ...?headers,
    };

    return _sendRequest(
      () => _dio.post(
        endpoint,
        data: xmlBody,
        onSendProgress: onSendProgress,
        options: Options(
          headers: requestHeaders,
          responseType: ResponseType.plain, // plain to keep XML payload as raw text string
        ),
      ),
    );
  }

  /// Sends a .NET SOAP request wrapping the inner body content inside a SOAP Envelope.
  Future<XmlResponse> postSoap({
    required String endpoint,
    required String soapAction,
    required String methodBody,
    String xmlns = 'http://tempuri.org/',
    Map<String, String>? headers,
  }) async {
    final String soapEnvelope = '''
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    $methodBody
  </soap:Body>
</soap:Envelope>
'''.trim();

    final Map<String, String> requestHeaders = {
      'Content-Type': 'text/xml; charset=utf-8',
      'SOAPAction': soapAction.startsWith('http') ? soapAction : '$xmlns$soapAction',
      ...?headers,
    };

    return _sendRequest(
      () => _dio.post(
        endpoint,
        data: soapEnvelope,
        options: Options(
          headers: requestHeaders,
          responseType: ResponseType.plain,
        ),
      ),
    );
  }

  /// Send Dio request and convert exceptions into human readable formats
  Future<XmlResponse> _sendRequest(Future<Response> Function() requestFn) async {
    try {
      final response = await requestFn();
      final responseBody = response.data?.toString() ?? '';
      
      return XmlResponse(
        body: responseBody,
        statusCode: response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      final errorMsg = _handleDioError(e);
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Handles Dio errors, extracts SOAP faults if returned by .NET server
  String _handleDioError(DioException error) {
    String? soapFault;
    if (error.response?.data != null) {
      soapFault = _extractSoapFault(error.response!.data.toString());
    }

    // If there is an XML SOAP fault, display it directly
    if (soapFault != null && soapFault.isNotEmpty) {
      return soapFault;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your network connection and try again.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        return 'Server returned error response (Status: $status).';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please verify your connection.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      default:
        return error.message ?? 'A network communication error occurred.';
    }
  }

  /// Helper to parse XML to get SOAP Fault reason/details
  String? _extractSoapFault(String responseBody) {
    try {
      final document = xml.XmlDocument.parse(responseBody);
      final faultStringNode = document.findAllElements('faultstring');
      if (faultStringNode.isNotEmpty) {
        return faultStringNode.first.innerText;
      }
      final reasonNode = document.findAllElements('soap:Reason');
      if (reasonNode.isNotEmpty) {
        return reasonNode.first.innerText;
      }
    } catch (_) {}
    return null;
  }
}

/// Custom Interceptor to display styled request, response, and error parameters in console logs.
class XmlLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('┌──────────────────────────────────────────────────────────────');
    print('│ 🚀 DIO XML REQUEST');
    print('├──────────────────────────────────────────────────────────────');
    print('│ URL: ${options.uri}');
    print('│ Method: ${options.method.toUpperCase()}');
    if (options.headers.isNotEmpty) {
      print('│ Headers:');
      options.headers.forEach((key, value) {
        print('│   $key: $value');
      });
    }
    if (options.data != null) {
      print('│ Body:');
      final bodyLines = options.data.toString().split('\n');
      for (var line in bodyLines) {
        print('│   $line');
      }
    }
    print('└──────────────────────────────────────────────────────────────');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('┌──────────────────────────────────────────────────────────────');
    print('│ ✅ DIO XML RESPONSE');
    print('├──────────────────────────────────────────────────────────────');
    print('│ URL: ${response.requestOptions.uri}');
    print('│ Status Code: ${response.statusCode}');
    if (response.data != null) {
      print('│ Body:');
      final bodyLines = response.data.toString().split('\n');
      for (var line in bodyLines) {
        print('│   $line');
      }
    }
    print('└──────────────────────────────────────────────────────────────');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('┌──────────────────────────────────────────────────────────────');
    print('│ ❌ DIO XML ERROR');
    print('├──────────────────────────────────────────────────────────────');
    print('│ URL: ${err.requestOptions.uri}');
    print('│ Error Type: ${err.type}');
    print('│ Status Code: ${err.response?.statusCode}');
    print('│ Message: ${err.message}');
    if (err.response?.data != null) {
      print('│ Error Body:');
      final bodyLines = err.response!.data.toString().split('\n');
      for (var line in bodyLines) {
        print('│   $line');
      }
    }
    print('└──────────────────────────────────────────────────────────────');
    super.onError(err, handler);
  }
}
