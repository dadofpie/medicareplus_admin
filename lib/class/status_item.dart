class StatusItem {
  final int id;
  final String status;

  StatusItem({required this.id, required this.status});

  // Convert StatusItem to a string for the dropdown
  @override
  String toString() => status;
}



class StringType {
  final String id;
  final String status;

  StringType({required this.id, required this.status});

  // Convert StatusItem to a string for the dropdown
  @override
  String toString() => status;
}
