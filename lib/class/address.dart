class Region {
  final String code;
  final String regionName;

  Region({required this.code, required this.regionName});

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      code: json['code'],
      regionName: json['regionName'],
    );
  }
}

class Province {
  final String code;
  final String name;

  Province({required this.code, required this.name});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      code: json['code'],
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
      code: json['code'],
      name: json['name'],
    );
  }
}

class Barangay {
  final String code;
  final String name;

  Barangay({required this.code, required this.name});

  factory Barangay.fromJson(Map<String, dynamic> json) {
    return Barangay(
      code: json['code'],
      name: json['name'],
    );
  }
}