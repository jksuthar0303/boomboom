import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class LocationController extends GetxController {
  var countries = [].obs;
  var cities = [].obs;
  var filteredCities = [].obs;

  var selectedCountry = "".obs;
  var selectedCity = "".obs;
  var fromCountry = "".obs;
  var fromCity = "".obs;
  var searchText = "".obs;
  var searchCityText = "".obs;
  var filteredCountries = [].obs;

  var destinationCountry = "".obs;
  var destinationCity = "".obs;

  var isLoadingCountries = false.obs;
  var isLoadingCities = false.obs;

  static const int _maxRetries = 2;

  /// 🔥 Countries
  Future<void> fetchCountries() async {
    isLoadingCountries.value = true;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final res = await http
            .get(Uri.parse("https://restcountries.com/v3.1/all?fields=name,flags,cca2"))
            .timeout(const Duration(seconds: 10));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);

          if (data is! List) {
            continue;
          }

          final list = data.map((e) {
            final name = e["name"]?["common"];
            if (name == null) return null;

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

          if (list.isEmpty) continue;

          list.sort((a, b) => a["name"].toString().compareTo(b["name"].toString()));

          countries.value = list;
          filteredCountries.value = List.from(countries);
          isLoadingCountries.value = false;
          return;
        }
      } catch (e) {
        debugPrint("Countries fetch attempt $attempt failed: $e");
      }
    }

    // Fallback countries
    countries.value = _fallbackCountries;
    filteredCountries.value = List.from(countries);
    isLoadingCountries.value = false;
  }

  static final List<Map<String, String?>> _fallbackCountries = [
    {"name": "Afghanistan", "code": "af"},
    {"name": "Australia", "code": "au"},
    {"name": "Austria", "code": "at"},
    {"name": "Bangladesh", "code": "bd"},
    {"name": "Belgium", "code": "be"},
    {"name": "Brazil", "code": "br"},
    {"name": "Canada", "code": "ca"},
    {"name": "China", "code": "cn"},
    {"name": "Denmark", "code": "dk"},
    {"name": "Egypt", "code": "eg"},
    {"name": "Finland", "code": "fi"},
    {"name": "France", "code": "fr"},
    {"name": "Germany", "code": "de"},
    {"name": "Greece", "code": "gr"},
    {"name": "Hong Kong", "code": "hk"},
    {"name": "India", "code": "in"},
    {"name": "Indonesia", "code": "id"},
    {"name": "Ireland", "code": "ie"},
    {"name": "Italy", "code": "it"},
    {"name": "Japan", "code": "jp"},
    {"name": "Malaysia", "code": "my"},
    {"name": "Maldives", "code": "mv"},
    {"name": "Mexico", "code": "mx"},
    {"name": "Nepal", "code": "np"},
    {"name": "Netherlands", "code": "nl"},
    {"name": "New Zealand", "code": "nz"},
    {"name": "Norway", "code": "no"},
    {"name": "Pakistan", "code": "pk"},
    {"name": "Philippines", "code": "ph"},
    {"name": "Portugal", "code": "pt"},
    {"name": "Qatar", "code": "qa"},
    {"name": "Russia", "code": "ru"},
    {"name": "Saudi Arabia", "code": "sa"},
    {"name": "Singapore", "code": "sg"},
    {"name": "South Africa", "code": "za"},
    {"name": "South Korea", "code": "kr"},
    {"name": "Spain", "code": "es"},
    {"name": "Sri Lanka", "code": "lk"},
    {"name": "Sweden", "code": "se"},
    {"name": "Switzerland", "code": "ch"},
    {"name": "Thailand", "code": "th"},
    {"name": "Turkey", "code": "tr"},
    {"name": "United Arab Emirates", "code": "ae"},
    {"name": "United Kingdom", "code": "gb"},
    {"name": "United States", "code": "us"},
    {"name": "Vietnam", "code": "vn"},
  ].map((c) {
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

  void filterCities(String text) {
    searchCityText.value = text;

    if (text.isEmpty) {
      filteredCities.value = List.from(cities);
    } else {
      filteredCities.value = cities.where((c) {
        return c.toString().toLowerCase().contains(text.toLowerCase());
      }).toList();
    }
  }

  /// 🔥 Fetch Cities by country with comprehensive fallback support
  Future<void> fetchCities(String country) async {
    final cleanCountry = country.trim();
    if (cleanCountry.isEmpty) {
      cities.clear();
      filteredCities.clear();
      return;
    }

    isLoadingCities.value = true;
    cities.clear();
    filteredCities.clear();
    searchCityText.value = "";

    try {
      final res = await http
          .post(
            Uri.parse("https://countriesnow.space/api/v0.1/countries/cities"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"country": cleanCountry}),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List? rawList = data["data"];
        if (rawList != null && rawList.isNotEmpty) {
          final loaded = List<String>.from(rawList);
          loaded.sort((a, b) => a.compareTo(b));
          cities.value = loaded;
          filteredCities.value = List.from(cities);
          isLoadingCities.value = false;
          return;
        }
      }
    } catch (e) {
      debugPrint("City API call failed: $e, checking fallback database");
    }

    // Lookup fallback database
    final fallbackList = _getFallbackCitiesForCountry(cleanCountry);
    cities.value = fallbackList;
    filteredCities.value = List.from(cities);
    isLoadingCities.value = false;
  }

  List<String> _getFallbackCitiesForCountry(String country) {
    final normalized = country.toLowerCase().trim();

    for (var entry in _fallbackCitiesMap.entries) {
      final key = entry.key.toLowerCase();
      if (normalized == key || normalized.contains(key) || key.contains(normalized)) {
        final list = List<String>.from(entry.value);
        list.sort((a, b) => a.compareTo(b));
        return list;
      }
    }

    // Default fallback popular international travel destinations
    return [
      "Capital City",
      "Downtown / Central",
      "Airport Area",
      "North Region",
      "South Region",
      "East Region",
      "West Region",
    ];
  }

  static final Map<String, List<String>> _fallbackCitiesMap = {
    "Australia": [
      "Sydney",
      "Melbourne",
      "Brisbane",
      "Perth",
      "Adelaide",
      "Gold Coast",
      "Canberra",
      "Newcastle",
      "Wollongong",
      "Hobart",
      "Darwin",
      "Cairns",
      "Geelong",
      "Townsville",
      "Sunshine Coast",
      "Toowoomba",
      "Ballarat",
      "Bendigo",
      "Albury",
      "Mackay",
      "Rockhampton",
      "Bunbury",
      "Coffs Harbour",
      "Bundaberg",
      "Wagga Wagga",
      "Hervey Bay",
      "Mildura",
      "Port Macquarie",
      "Gladstone",
      "Tamworth",
    ],
    "India": [
      "Mumbai",
      "Delhi",
      "Bengaluru",
      "Hyderabad",
      "Chennai",
      "Kolkata",
      "Ahmedabad",
      "Pune",
      "Jaipur",
      "Surat",
      "Lucknow",
      "Kanpur",
      "Nagpur",
      "Indore",
      "Thane",
      "Bhopal",
      "Visakhapatnam",
      "Patna",
      "Vadodara",
      "Ghaziabad",
      "Ludhiana",
      "Agra",
      "Nashik",
      "Faridabad",
      "Varanasi",
      "Meerut",
      "Rajkot",
      "Amritsar",
      "Allahabad",
      "Coimbatore",
      "Jabalpur",
      "Gwalior",
      "Vijayawada",
      "Jodhpur",
      "Madurai",
      "Raipur",
      "Kota",
      "Guwahati",
      "Chandigarh",
      "Solapur",
      "Hubli-Dharwad",
      "Bareilly",
      "Moradabad",
      "Mysore",
      "Gurgaon",
      "Aligarh",
      "Jalandhar",
      "Tiruchirappalli",
      "Bhubaneswar",
      "Salem",
      "Goa",
      "Kochi",
      "Noida",
      "Dehradun",
      "Shimla",
      "Udaipur",
    ],
    "United States": [
      "New York",
      "Los Angeles",
      "Chicago",
      "Houston",
      "Phoenix",
      "Philadelphia",
      "San Antonio",
      "San Diego",
      "Dallas",
      "San Jose",
      "Austin",
      "Jacksonville",
      "Fort Worth",
      "Columbus",
      "Charlotte",
      "San Francisco",
      "Indianapolis",
      "Seattle",
      "Denver",
      "Washington",
      "Boston",
      "El Paso",
      "Nashville",
      "Detroit",
      "Oklahoma City",
      "Portland",
      "Las Vegas",
      "Memphis",
      "Louisville",
      "Baltimore",
      "Milwaukee",
      "Albuquerque",
      "Tucson",
      "Fresno",
      "Mesa",
      "Sacramento",
      "Atlanta",
      "Kansas City",
      "Colorado Springs",
      "Miami",
      "Raleigh",
      "Omaha",
      "Long Beach",
      "Virginia Beach",
      "Oakland",
      "Minneapolis",
      "Tampa",
      "Tulsa",
      "Arlington",
      "New Orleans",
      "Orlando",
      "Honolulu",
    ],
    "United Kingdom": [
      "London",
      "Birmingham",
      "Manchester",
      "Glasgow",
      "Liverpool",
      "Bristol",
      "Edinburgh",
      "Leeds",
      "Sheffield",
      "Newcastle upon Tyne",
      "Belfast",
      "Nottingham",
      "Southampton",
      "Leicester",
      "Coventry",
      "Hull",
      "Bradford",
      "Cardiff",
      "Stoke-on-Trent",
      "Wolverhampton",
      "Plymouth",
      "Derby",
      "Swansea",
      "Aberdeen",
      "Southampton",
      "Brighton",
      "Oxford",
      "Cambridge",
      "York",
      "Bath",
    ],
    "United Arab Emirates": [
      "Dubai",
      "Abu Dhabi",
      "Sharjah",
      "Ajman",
      "Ras Al Khaimah",
      "Fujairah",
      "Umm Al Quwain",
      "Al Ain",
      "Khor Fakkan",
      "Dibba Al-Fujairah",
      "Hatta",
      "Madinat Zayed",
    ],
    "Thailand": [
      "Bangkok",
      "Phuket",
      "Chiang Mai",
      "Pattaya",
      "Krabi",
      "Koh Samui",
      "Hua Hin",
      "Chiang Rai",
      "Surat Thani",
      "Hat Yai",
      "Udon Thani",
      "Nakhon Ratchasima",
      "Ayutthaya",
      "Kanchanaburi",
      "Chon Buri",
      "Rayong",
      "Koh Phangan",
      "Koh Tao",
    ],
    "Canada": [
      "Toronto",
      "Montreal",
      "Vancouver",
      "Calgary",
      "Edmonton",
      "Ottawa",
      "Winnipeg",
      "Quebec City",
      "Hamilton",
      "Kitchener",
      "London",
      "Victoria",
      "Halifax",
      "Oshawa",
      "Windsor",
      "Saskatoon",
      "Regina",
      "St. John's",
      "Kelowna",
      "Barrie",
      "Niagara Falls",
    ],
    "Singapore": [
      "Singapore City",
      "Marina Bay",
      "Orchard",
      "Sentosa",
      "Jurong",
      "Tampines",
      "Woodlands",
      "Bedok",
      "Changi",
      "Yishun",
      "Novena",
      "Bukit Timah",
    ],
    "Germany": [
      "Berlin",
      "Munich",
      "Frankfurt",
      "Hamburg",
      "Cologne",
      "Stuttgart",
      "Dusseldorf",
      "Dortmund",
      "Essen",
      "Leipzig",
      "Bremen",
      "Dresden",
      "Hanover",
      "Nuremberg",
      "Duisburg",
      "Bonn",
    ],
    "France": [
      "Paris",
      "Marseille",
      "Lyon",
      "Toulouse",
      "Nice",
      "Nantes",
      "Strasbourg",
      "Montpellier",
      "Bordeaux",
      "Lille",
      "Rennes",
      "Reims",
      "Cannes",
      "Monaco",
    ],
    "Spain": [
      "Madrid",
      "Barcelona",
      "Valencia",
      "Seville",
      "Zaragoza",
      "Malaga",
      "Murcia",
      "Palma",
      "Las Palmas",
      "Bilbao",
      "Alicante",
      "Cordoba",
      "Ibiza",
      "Granada",
    ],
    "Italy": [
      "Rome",
      "Milan",
      "Naples",
      "Turin",
      "Palermo",
      "Genoa",
      "Bologna",
      "Florence",
      "Bari",
      "Catania",
      "Venice",
      "Verona",
      "Messina",
      "Padua",
      "Trieste",
    ],
    "Japan": [
      "Tokyo",
      "Yokohama",
      "Osaka",
      "Nagoya",
      "Sapporo",
      "Fukuoka",
      "Kobe",
      "Kyoto",
      "Kawasaki",
      "Saitama",
      "Hiroshima",
      "Sendai",
      "Chiba",
      "Nara",
      "Okinawa",
    ],
    "China": [
      "Beijing",
      "Shanghai",
      "Guangzhou",
      "Shenzhen",
      "Chengdu",
      "Hangzhou",
      "Wuhan",
      "Xi'an",
      "Chongqing",
      "Nanjing",
      "Tianjin",
      "Suzhou",
      "Hong Kong",
      "Macau",
    ],
    "Pakistan": [
      "Karachi",
      "Lahore",
      "Faisalabad",
      "Rawalpindi",
      "Gujranwala",
      "Peshawar",
      "Multan",
      "Hyderabad",
      "Islamabad",
      "Quetta",
      "Sialkot",
      "Bahawalpur",
    ],
    "Saudi Arabia": [
      "Riyadh",
      "Jeddah",
      "Mecca",
      "Medina",
      "Dammam",
      "Khobar",
      "Tabuk",
      "Taif",
      "Abha",
      "Jubail",
    ],
    "Indonesia": [
      "Jakarta",
      "Surabaya",
      "Bandung",
      "Medan",
      "Bekasi",
      "Tangerang",
      "Depok",
      "Semarang",
      "Palembang",
      "Makassar",
      "Bali / Denpasar",
      "Yogyakarta",
    ],
    "Malaysia": [
      "Kuala Lumpur",
      "George Town / Penang",
      "Johor Bahru",
      "Ipoh",
      "Shah Alam",
      "Petaling Jaya",
      "Kota Kinabalu",
      "Melaka",
      "Kuching",
      "Langkawi",
    ],
    "New Zealand": [
      "Auckland",
      "Wellington",
      "Christchurch",
      "Hamilton",
      "Tauranga",
      "Napier-Hastings",
      "Dunedin",
      "Palmerston North",
      "Nelson",
      "Rotorua",
      "Queenstown",
    ],
    "Russia": [
      "Moscow",
      "Saint Petersburg",
      "Novosibirsk",
      "Yekaterinburg",
      "Kazan",
      "Nizhny Novgorod",
      "Chelyabinsk",
      "Samara",
      "Omsk",
      "Rostov-on-Don",
      "Sochi",
      "Vladivostok",
    ],
    "Brazil": [
      "Sao Paulo",
      "Rio de Janeiro",
      "Brasilia",
      "Salvador",
      "Fortaleza",
      "Belo Horizonte",
      "Manaus",
      "Curitiba",
      "Recife",
      "Porto Alegre",
    ],
    "South Africa": [
      "Johannesburg",
      "Cape Town",
      "Durban",
      "Pretoria",
      "Port Elizabeth",
      "Bloemfontein",
      "East London",
      "Nelspruit",
    ],
    "Turkey": [
      "Istanbul",
      "Ankara",
      "Izmir",
      "Bursa",
      "Antalya",
      "Adana",
      "Konya",
      "Gaziantep",
      "Sanliurfa",
      "Bodrum",
      "Cappadocia",
    ],
  };
}