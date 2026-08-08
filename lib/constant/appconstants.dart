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

  static String cleanEmoji(String? input) {
    if (input == null || input.trim().isEmpty) return '';
    return input
        .replaceAll(
          RegExp(
            r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{2300}-\u{23FF}\u{2B50}\u{2B55}\u{203C}\u{2049}\u{2122}\u{2139}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{231A}-\u{231B}\u{2328}\u{23CF}\u{23E9}-\u{23F3}\u{23F8}-\u{23FA}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}]',
            unicode: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
