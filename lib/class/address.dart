class Region {
  final String code;
  final String regionName;

  Region({required this.code, required this.regionName});

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      code: json['id'].toString(),
      regionName: json['name'],
    );
  }
}

class Province {
  final String code;
  final String name;

  Province({required this.code, required this.name});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      code: json['id'].toString(),
      name: json['name'],
    );
  }
}

class City {
  final String code;
  final String name;

  City({required this.code, required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      code: json['id'].toString(),
      name: json['name'],
    );
  }
}

class Barangay {
  final String code;
  final String name;
  final String postal;

  Barangay({required this.code, required this.name, required this.postal});

  factory Barangay.fromJson(Map<String, dynamic> json) {
    return Barangay(
      code: json['id'].toString(),
      name: json['name'],
      postal:json['postal_code']
    );
  }
}