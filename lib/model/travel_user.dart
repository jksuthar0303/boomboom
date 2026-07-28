import 'package:xml/xml.dart' as xml;

class TravelUser {
  final String id;
  final String name;
  final int age;
  final String flag;
  final String height;
  final String fromLocation;
  final String toLocation;
  final String tag;
  final String status;
  final String image;

  TravelUser({
    required this.id,
    required this.name,
    required this.age,
    required this.flag,
    required this.height,
    required this.fromLocation,
    required this.toLocation,
    required this.tag,
    required this.status,
    required this.image,
  });

  /// Factory to parse XML element into Dart Model
  factory TravelUser.fromXml(xml.XmlElement element) {
    String getElementText(String name) {
      final elements = element.findElements(name);
      return elements.isNotEmpty ? elements.first.innerText : '';
    }

    return TravelUser(
      id: getElementText('Id'),
      name: getElementText('Name'),
      age: int.tryParse(getElementText('Age')) ?? 0,
      flag: getElementText('Flag'),
      height: getElementText('Height'),
      fromLocation: getElementText('FromLocation'),
      toLocation: getElementText('ToLocation'),
      tag: getElementText('Tag'),
      status: getElementText('Status'),
      image: getElementText('Image'),
    );
  }

  /// Converts model back to map for optional json or debugging use
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'flag': flag,
      'height': height,
      'from': fromLocation,
      'to': toLocation,
      'tag': tag,
      'status': status,
      'image': image,
    };
  }

  /// Converts the model parameters to a partial XML snippet for request bodies
  String toXmlSnippet() {
    return '''
      <Id>$id</Id>
      <Name>$name</Name>
      <Age>$age</Age>
      <Flag>$flag</Flag>
      <Height>$height</Height>
      <FromLocation>$fromLocation</FromLocation>
      <ToLocation>$toLocation</ToLocation>
      <Tag>$tag</Tag>
      <Status>$status</Status>
      <Image>$image</Image>
    '''.trim();
  }
}
