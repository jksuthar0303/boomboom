import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class LocationController extends GetxController {
  var countries = [].obs;
  var cities = [].obs;

  var selectedCountry = "".obs;
  var selectedCity = "".obs;
  var fromCountry = "".obs;
  var fromCity = "".obs;
  var searchText = "".obs;
  var filteredCountries = [].obs;

  var destinationCountry = "".obs;
  var destinationCity = "".obs;

  /// 🔥 loading flags so UI can show a spinner / "Loading countries..." text
  var isLoadingCountries = false.obs;
  var isLoadingCities = false.obs;

  /// 🔥 retry attempts before falling back to the static list
  static const int _maxRetries = 2;

  /// 🔥 Countries
  Future<void> fetchCountries() async {
    isLoadingCountries.value = true;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        print("🔥 API CALL START (attempt $attempt)");

        final res = await http
            .get(Uri.parse("https://restcountries.com/v3.1/all?fields=name,flags,cca2"))
            .timeout(const Duration(seconds: 10));

        print("🔥 STATUS CODE: ${res.statusCode}");

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);

          // 🔥 restcountries.com sometimes returns an error object instead of
          // a list (rate-limited, maintenance, bad query, etc). Guard against that.
          if (data is! List) {
            print("❌ UNEXPECTED RESPONSE SHAPE (not a List): ${res.body}");
            continue; // try again, then fall through to fallback list
          }

          print("🔥 TOTAL COUNTRIES: ${data.length}");

          final list = data.map((e) {
            final name = e["name"]?["common"];
            if (name == null) return null; // skip malformed entries

            // 🔥 prefer restcountries' own flag PNG, but fall back to
            // flagcdn.com (using the ISO-2 code) if it's missing/null —
            // this guarantees every row gets a real, unique flag image.
            String? flag = e["flags"]?["png"];
            final code = e["cca2"]?.toString().toLowerCase();
            if ((flag == null || flag.isEmpty) && code != null) {
              flag = "https://flagcdn.com/w80/$code.png";
            }

            return {
              "name": name,
              "flag": flag,
            };
          }).whereType<Map>().toList();

          if (list.isEmpty) {
            print("❌ PARSED LIST EMPTY, retrying / will fallback");
            continue;
          }

          // sort alphabetically so the list + fast letter search feels natural
          list.sort((a, b) => a["name"].toString().compareTo(b["name"].toString()));

          countries.value = list;
          filteredCountries.value = List.from(countries); // 🔥 copy the VALUE, not the Rx wrapper

          print("🔥 LOADED ${countries.length} COUNTRIES SUCCESSFULLY");
          isLoadingCountries.value = false;
          return; // success, stop retrying
        } else {
          print("❌ API FAILED with status ${res.statusCode}");
          print("❌ BODY: ${res.body}");
        }
      } catch (e) {
        print("❌ ERROR (attempt $attempt): $e");
      }
    }

    // 🔥 all attempts failed -> use the static fallback list so the UI is never empty
    print("⚠️ FALLING BACK TO STATIC COUNTRY LIST");
    countries.value = _fallbackCountries;
    filteredCountries.value = List.from(countries);
    isLoadingCountries.value = false;
  }

  /// 🔥 minimal offline fallback so users still see a usable list (with real
  /// flags via flagcdn.com) if the live API is rate-limited or unreachable.
  /// Expand this list as needed — just add the ISO-2 country code.
  static final List<Map<String, String?>> _fallbackCountries = [
    {"name": "Afghanistan", "code": "af"},
    {"name": "Australia", "code": "au"},
    {"name": "Bangladesh", "code": "bd"},
    {"name": "Brazil", "code": "br"},
    {"name": "Canada", "code": "ca"},
    {"name": "China", "code": "cn"},
    {"name": "Egypt", "code": "eg"},
    {"name": "France", "code": "fr"},
    {"name": "Germany", "code": "de"},
    {"name": "India", "code": "in"},
    {"name": "Indonesia", "code": "id"},
    {"name": "Italy", "code": "it"},
    {"name": "Japan", "code": "jp"},
    {"name": "Malaysia", "code": "my"},
    {"name": "Mexico", "code": "mx"},
    {"name": "Nepal", "code": "np"},
    {"name": "Pakistan", "code": "pk"},
    {"name": "Philippines", "code": "ph"},
    {"name": "Russia", "code": "ru"},
    {"name": "Saudi Arabia", "code": "sa"},
    {"name": "Singapore", "code": "sg"},
    {"name": "South Africa", "code": "za"},
    {"name": "South Korea", "code": "kr"},
    {"name": "Spain", "code": "es"},
    {"name": "Sri Lanka", "code": "lk"},
    {"name": "Thailand", "code": "th"},
    {"name": "Turkey", "code": "tr"},
    {"name": "United Arab Emirates", "code": "ae"},
    {"name": "United Kingdom", "code": "gb"},
    {"name": "United States", "code": "us"},
  ].map((c) {
    // 🔥 flagcdn.com serves a real PNG flag for every ISO-2 code, e.g.
    // https://flagcdn.com/w80/in.png -> India's flag
    return {
      "name": c["name"],
      "flag": "https://flagcdn.com/w80/${c["code"]}.png",
    };
  }).toList()
    ..sort((a, b) => a["name"]!.compareTo(b["name"]!));

  void filterCountries(String text) {
    searchText.value = text;

    if (text.isEmpty) {
      filteredCountries.value = List.from(countries);
    } else {
      filteredCountries.value = countries.where((c) {
        return c["name"].toString().toLowerCase().contains(text.toLowerCase());
      }).toList();
    }
  }

  /// 🔥 Cities by country
  Future<void> fetchCities(String country) async {
    try {
      isLoadingCities.value = true;
      cities.clear();

      final res = await http.post(
        Uri.parse("https://countriesnow.space/api/v0.1/countries/cities"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"country": country}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        cities.value = List<String>.from(data["data"] ?? []);
      } else {
        cities.clear();
        print("❌ CITY API FAILED with status ${res.statusCode}");
      }
    } catch (e) {
      print("❌ CITY ERROR: $e");
      cities.clear();
    } finally {
      isLoadingCities.value = false;
    }
  }
}