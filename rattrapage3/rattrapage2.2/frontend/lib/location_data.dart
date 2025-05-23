import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Country {
  final String name;
  final String iso2;
  Country({required this.name, required this.iso2});
  factory Country.fromJson(Map<String, dynamic> json) =>
      Country(name: json['name'], iso2: json['iso2']);
}

class City {
  final String name;
  final String countryIso2;
  City({required this.name, required this.countryIso2});
  factory City.fromJson(Map<String, dynamic> json) =>
      City(name: json['name'], countryIso2: json['country_code']);
}

class LocationDataProvider {
  static List<Country>? _countriesCache;
  static Map<String, List<City>>? _citiesByCountryCache;

  static Future<List<Country>> loadCountries() async {
    if (_countriesCache != null) return _countriesCache!;
    final data = await rootBundle.loadString('assets/countries.json');
    final List<dynamic> jsonList = json.decode(data);
    _countriesCache = jsonList.map((e) => Country.fromJson(e)).toList();
    return _countriesCache!;
  }

  static Future<List<City>> loadCities(String countryIso2) async {
    _citiesByCountryCache ??= {};
    if (_citiesByCountryCache!.containsKey(countryIso2)) {
      return _citiesByCountryCache![countryIso2]!;
    }
    final data = await rootBundle.loadString('assets/cities.json');
    final List<dynamic> jsonList = json.decode(data);
    final allCities = jsonList.map((e) => City.fromJson(e)).toList();
    final cities =
        allCities.where((c) => c.countryIso2 == countryIso2).toList();
    _citiesByCountryCache![countryIso2] = cities;
    return cities;
  }
}
