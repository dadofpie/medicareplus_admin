import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:medicare_admin_remaster/class/address.dart';

class LocationProvider extends ChangeNotifier {
  String? selectedRegion;
  String? selectedProvince;
  String? selectedCity;

  List<Region> regions = [];
  List<Province> provinces = [];
  List<City> cities = [];
  List<Barangay> barangays = [];

  bool isLoading = false; // Loading state

  Future<void> fetchRegions() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/regions.json'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        regions = data.map((e) => Region.fromJson(e)).toList();
      } else {
        // Handle server errors
        throw Exception('Failed to load regions');
      }
    } catch (e) {
      // Handle errors
      print(e); // Log the error
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProvinces(String regionCode) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/regions/$regionCode/provinces.json'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        provinces = data.map((e) => Province.fromJson(e)).toList();
        selectedProvince = null; // Reset province selection
        cities.clear(); // Clear cities
        barangays.clear(); // Clear barangays
      } else {
        throw Exception('Failed to load provinces');
      }
    } catch (e) {
      print(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCities(String provinceCode) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/provinces/$provinceCode/cities.json'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        cities = data.map((e) => City.fromJson(e)).toList();
        selectedCity = null; // Reset city selection
        barangays.clear(); // Clear barangays
      } else {
        throw Exception('Failed to load cities');
      }
    } catch (e) {
      print(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBarangays(String cityCode) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/cities/$cityCode/barangays.json'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        barangays = data.map((e) => Barangay.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load barangays');
      }
    } catch (e) {
      print(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
