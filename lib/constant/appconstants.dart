class AppConstants {
  static const String baseUrl = 'https://boomboomdate.com/';
  static const String apiEndpoint = 'APIs/WebService1.asmx';
  static const String tempuriNamespace = 'http://tempuri.org/';
  static const String dummyToken = 'BAHABAAOAMOOAMAA';

  static const List<String> interestOptions = [
    "Music 🎵",
    "Travel ✈️",
    "Photography 📸",
    "Fitness 🏃",
    "Cooking 🍳",
    "Reading 📚",
    "Movies 🎬",
    "Art 🎨",
    "Sports ⚽",
    "Gaming 🎮",
    "Yoga 🧘",
    "Wine 🍷",
    "Hiking 🏔️",
    "Pets 🐕",
    "Dancing 💃",
    "Comedy 🎭",
  ];

  static String? findMatchingInterest(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final cleanVal = val
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z]'), '')
        .trim();
    if (cleanVal.isEmpty) return null;
    for (var opt in interestOptions) {
      final cleanOpt = opt
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-zA-Z]'), '')
          .trim();
      if (cleanOpt == cleanVal ||
          cleanOpt.contains(cleanVal) ||
          cleanVal.contains(cleanOpt)) {
        return opt;
      }
    }
    return null;
  }
}
