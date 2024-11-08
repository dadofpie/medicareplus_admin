import 'package:medicare_admin_remaster/class/status_item.dart';

final List<StatusItem> memberTypeItems = [
    StatusItem(id: 1, status: 'Principal'),
    StatusItem(id: 2, status: 'Dependent')
  ];

final List<StatusItem> enrollmentTypeItems = [
    StatusItem(id: 1, status: 'New'),
    StatusItem(id: 2, status: 'Renewal'),
    StatusItem(id: 3, status: 'Additional'),
    StatusItem(id: 4, status: 'Upgrade'),
  ];


final List<StatusItem> planTypeItems = [
    //StatusItem(id: 1, status: 'ER GUARD'),
    //StatusItem(id: 2, status: 'ER GUARD PLUS'),
    //StatusItem(id: 3, status: 'CARE CENTER - CONNECT'),
    StatusItem(id: 4, status: 'COMPREHENSIVE - PSMBFI')
  ];

final List<StatusItem> roomBoardTypeItems = [
    StatusItem(id: 1, status: 'Ward'),
    StatusItem(id: 2, status: 'Semi Private'),
    StatusItem(id: 3, status: 'Private'),
    StatusItem(id: 4, status: 'Large Private'),
    StatusItem(id: 5, status: 'Open'),
    StatusItem(id: 6, status: 'Open Ward'),
    StatusItem(id: 7, status: 'Open Semi Private'),
    StatusItem(id: 8, status: 'Open Private'),
    StatusItem(id: 9, status: 'Suite')
  ];

final List<StatusItem> benefitTypeItems = [
    StatusItem(id: 1, status: 'ABL'),
    StatusItem(id: 2, status: 'MBL'),
    StatusItem(id: 3, status: 'EL')
  ];


final List<StringType> civilStatusTypeItems = [
    StringType(id: "Single", status: 'Single'),
    StringType(id: "Married", status: 'Married'),
    StringType(id: "Divorced", status: "Divorced"),
    StringType(id: "Widowed", status: "Widowed")
  ];

final List<StatusItem> adminTypeItems = [
    StatusItem(id: 1, status: 'Concierge'),
    StatusItem(id: 2, status: 'Admin'),
    StatusItem(id: 3, status: 'UPD'),
    StatusItem(id: 4, status: 'Claims'),
  ];

final List<StringType> adminStatusItems = [
    StringType(id: "active", status: 'Active'),
    StringType(id: "inactive", status: 'Inactive')
  ];