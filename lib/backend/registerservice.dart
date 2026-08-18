import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'xml_api_client.dart';
import '../constant/appconstants.dart';

class RegisterService {
  final XmlApiClient _client;

  RegisterService({XmlApiClient? client})
    : _client = client ?? XmlApiClient(baseUrl: AppConstants.baseUrl);

  static const String namespace = AppConstants.tempuriNamespace;

  /// SOAP RegisterInsert request
  Future<XmlResponse> registerInsert({
    required String email,
    required String fullName,
    required String dob,
    required String password,
    required String bio,
    required String gender,
    required String lookingFor,
    required String orientation,
    required String occupation,
    required String lat,
    required String lon,
    required String height,
    required String bodyType,
    required String drinkingHabits,
    required String workout,
  }) async {
    final String cleanBodyType = AppConstants.cleanEmoji(bodyType);
    final String cleanDrinkingHabits = AppConstants.cleanEmoji(drinkingHabits);
    final String cleanWorkout = AppConstants.cleanEmoji(workout);
    final String cleanOccupation = AppConstants.cleanEmoji(occupation);
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <RegisterInsert xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <EmailAddress>$email</EmailAddress>
      <FullName>$fullName</FullName>
      <Dob>$dob</Dob>
      <AppPassword>$password</AppPassword>
      <Gender>$gender</Gender>
      <Lookingfor>$lookingFor</Lookingfor>
      <Orientation>$orientation</Orientation>
      <BIO>$bio</BIO>
      <Occupation>$cleanOccupation</Occupation>
      <Lat>$lat</Lat>
      <Lon>$lon</Lon>
      <Height>$height</Height>
      <BodyType>$cleanBodyType</BodyType>
      <DrinkingHabits>$cleanDrinkingHabits</DrinkingHabits>
      <Workout>$cleanWorkout</Workout>
      <FCMToken></FCMToken>
    </RegisterInsert>
  </soap12:Body>
</soap12:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {'Content-Type': 'application/soap+xml; charset=utf-8'},
    );
  }

  /// SOAP MediaInsert request
  Future<XmlResponse> mediaInsert({
    required String email,
    required String mediaBase64,
    required String type,
    ProgressCallback? onSendProgress,
  }) async {
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <MediaInsert xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <Media>$mediaBase64</Media>
      <Email>$email</Email>
      <Type>$type</Type>
    </MediaInsert>
  </soap12:Body>
</soap12:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      onSendProgress: onSendProgress,
      headers: {
        'Content-Type': 'application/soap+xml; charset=utf-8',
        'SOAPAction': '"${namespace}MediaInsert"',
      },
    );
  }

  /// SOAP MediaDelete request
  Future<XmlResponse> mediaDelete({
    required int id,
    required String email,
  }) async {
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <MediaDelete xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <Id>$id</Id>
      <Email>$email</Email>
    </MediaDelete>
  </soap:Body>
</soap:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"http://tempuri.org/MediaDelete"',
      },
    );
  }

  /// SOAP Login request
  Future<XmlResponse> login({
    required String email,
    required String password,
    String fcmToken = "",
  }) async {
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <Login xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <EmailAddress>$email</EmailAddress>
      <AppPassword>$password</AppPassword>
      <FCMToken>$fcmToken</FCMToken>
    </Login>
  </soap12:Body>
</soap12:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {'Content-Type': 'application/soap+xml; charset=utf-8'},
    );
  }

  /// SOAP SendEmailOTP request
  Future<XmlResponse> sendEmailOTP({
    required String email,
    required String otp,
  }) async {
    debugPrint("🔥 [SendEmailOTP Request] Email: $email, OTP: $otp");

    final String cleanEmail = email
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
    final String cleanOtp = otp
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <SendEmailOTP xmlns="$namespace">
      <Email>$cleanEmail</Email>
      <OTP>$cleanOtp</OTP>
    </SendEmailOTP>
  </soap:Body>
</soap:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}SendEmailOTP"',
      },
    );
  }

  /// SOAP UpdateFCMToken request
  Future<XmlResponse> updateFCMToken({
    required String email,
    required String fcmToken,
  }) async {
    debugPrint("🔥 [UpdateFCMToken Request] Email: $email");
    debugPrint("🔥 [UpdateFCMToken Request] Token: $fcmToken");

    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <UpdateFCMToken xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <EmailAddress>$email</EmailAddress>
      <FCMToken>$fcmToken</FCMToken>
    </UpdateFCMToken>
  </soap:Body>
</soap:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"${namespace}UpdateFCMToken"',
      },
    );
  }

  /// SOAP ShowProfile request
  Future<XmlResponse> showProfile({required String email}) async {
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ShowProfile xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <EmailAddress>$email</EmailAddress>
    </ShowProfile>
  </soap12:Body>
</soap12:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {'Content-Type': 'application/soap+xml; charset=utf-8'},
    );
  }

  /// SOAP ForgotPassword request
  Future<XmlResponse> forgotPassword({
    required String email,
    required String newPassword,
  }) async {
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <ForgotPassword xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <EmailAddress>$email</EmailAddress>
      <NewPassword>$newPassword</NewPassword>
    </ForgotPassword>
  </soap:Body>
</soap:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"http://tempuri.org/ForgotPassword"',
      },
    );
  }

  /// SOAP UpdateOnlineStatus request
  Future<XmlResponse> updateOnlineStatus({
    required String email,
    required bool isOnline,
  }) async {
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <UpdateOnlineStatus xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <EmailAddress>$email</EmailAddress>
      <IsOnline>${isOnline ? 'True' : 'False'}</IsOnline>
    </UpdateOnlineStatus>
  </soap:Body>
</soap:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"http://tempuri.org/UpdateOnlineStatus"',
      },
    );
  }

  /// SOAP DeleteAccount request
  Future<XmlResponse> deleteAccount({
    required String email,
    required String password,
  }) async {
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <DeleteAccount xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <EmailAddress>$email</EmailAddress>
      <AppPassword>$password</AppPassword>
    </DeleteAccount>
  </soap12:Body>
</soap12:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {'Content-Type': 'application/soap+xml; charset=utf-8'},
    );
  }

  /// SOAP InterestInsert request
  Future<XmlResponse> interestInsert({
    required String email,
    required String interest,
  }) async {
    final String cleanInterest = interest
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '')
        .trim();
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <InterestInsert xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <Interest>$cleanInterest</Interest>
      <Email>$email</Email>
    </InterestInsert>
  </soap12:Body>
</soap12:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {'Content-Type': 'application/soap+xml; charset=utf-8'},
    );
  }

  /// SOAP LifestyleInsert request
  Future<XmlResponse> lifestyleInsert({
    required String email,
    required String lifestyle,
  }) async {
    final String cleanLifestyle = AppConstants.cleanEmoji(lifestyle);
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <LifestyleInsert xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <LifeStyle>$cleanLifestyle</LifeStyle>
      <Email>$email</Email>
    </LifestyleInsert>
  </soap12:Body>
</soap12:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {'Content-Type': 'application/soap+xml; charset=utf-8'},
    );
  }

  /// SOAP ShowInterestByEmail request
  Future<XmlResponse> showInterestByEmail({required String email}) async {
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ShowInterestByEmail xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <Email>$email</Email>
    </ShowInterestByEmail>
  </soap12:Body>
</soap12:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {'Content-Type': 'application/soap+xml; charset=utf-8'},
    );
  }

  /// SOAP ShowLifestyleByEmail request
  Future<XmlResponse> showLifestyleByEmail({required String email}) async {
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ShowLifestyleByEmail xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <Email>$email</Email>
    </ShowLifestyleByEmail>
  </soap12:Body>
</soap12:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {'Content-Type': 'application/soap+xml; charset=utf-8'},
    );
  }

  /// SOAP UpdateVerification request
  Future<XmlResponse> updateVerification({
    required String email,
    required String isVerified,
  }) async {
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <UpdateVerification xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <EmailAddress>$email</EmailAddress>
      <IsVerified>$isVerified</IsVerified>
    </UpdateVerification>
  </soap:Body>
</soap:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"http://tempuri.org/UpdateVerification"',
      },
    );
  }

  /// SOAP Feedback_Insert request
  Future<XmlResponse> feedbackInsert({
    required String type,
    required String description,
    required String email,
  }) async {
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <Feedback_Insert xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <type>$type</type>
      <description>$description</description>
      <email>$email</email>
    </Feedback_Insert>
  </soap:Body>
</soap:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"http://tempuri.org/Feedback_Insert"',
      },
    );
  }

  /// SOAP ShowMediaByEmail request
  Future<XmlResponse> showMediaByEmail({
    required String email,
    required String type,
  }) async {
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ShowMediaByEmail xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <Email>$email</Email>
      <Type>$type</Type>
    </ShowMediaByEmail>
  </soap12:Body>
</soap12:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {'Content-Type': 'application/soap+xml; charset=utf-8'},
    );
  }

  /// SOAP UpdateLatLon request
  Future<XmlResponse> updateLatLon({
    required String email,
    required String lat,
    required String lon,
  }) async {
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <UpdateLatLon xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <EmailAddress>$email</EmailAddress>
      <Lat>$lat</Lat>
      <Lon>$lon</Lon>
    </UpdateLatLon>
  </soap:Body>
</soap:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"http://tempuri.org/UpdateLatLon"',
      },
    );
  }

  /// SOAP UpdateProfile request
  Future<XmlResponse> updateProfile({
    required String email,
    required String fullName,
    required String dob,
    required String gender,
    required String lookingFor,
    required String orientation,
    required String bio,
    required String occupation,
    required String height,
    required String bodyType,
    required String drinkingHabits,
    required String workout,
    String profileImage = '',
    ProgressCallback? onSendProgress,
  }) async {
    final String cleanBodyType = AppConstants.cleanEmoji(bodyType);
    final String cleanDrinkingHabits = AppConstants.cleanEmoji(drinkingHabits);
    final String cleanWorkout = AppConstants.cleanEmoji(workout);
    final String cleanOccupation = AppConstants.cleanEmoji(occupation);
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <UpdateProfile xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <EmailAddress>$email</EmailAddress>
      <FullName>$fullName</FullName>
      <Dob>$dob</Dob>
      <Gender>$gender</Gender>
      <Lookingfor>$lookingFor</Lookingfor>
      <Orientation>$orientation</Orientation>
      <BIO>$bio</BIO>
      <Occupation>$cleanOccupation</Occupation>
      <Height>$height</Height>
      <BodyType>$cleanBodyType</BodyType>
      <DrinkingHabits>$cleanDrinkingHabits</DrinkingHabits>
      <Workout>$cleanWorkout</Workout>
      <ProfileImage>$profileImage</ProfileImage>
    </UpdateProfile>
  </soap:Body>
</soap:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      onSendProgress: onSendProgress,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"http://tempuri.org/UpdateProfile"',
      },
    );
  }

  /// SOAP InterestDelete request
  Future<XmlResponse> interestDelete({
    required int id,
    required String email,
  }) async {
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <InterestDelete xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <Id>$id</Id>
      <Email>$email</Email>
    </InterestDelete>
  </soap:Body>
</soap:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"http://tempuri.org/InterestDelete"',
      },
    );
  }

  /// SOAP ShowCompleteProfile request
  Future<XmlResponse> showCompleteProfile({required String email}) async {
    final String xmlBody =
        '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <ShowCompleteProfile xmlns="$namespace">
      <token>${AppConstants.dummyToken}</token>
      <EmailAddress>$email</EmailAddress>
    </ShowCompleteProfile>
  </soap:Body>
</soap:Envelope>'''
            .trim();

    return await _client.postXml(
      endpoint: AppConstants.apiEndpoint,
      xmlBody: xmlBody,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"http://tempuri.org/ShowCompleteProfile"',
      },
    );
  }
}
