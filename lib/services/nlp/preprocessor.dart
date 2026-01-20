// Text Preprocessor for NLP operations
// Handles normalization, tokenization, and text cleaning

class Preprocessor {
  // Turkish character normalization map
  static const Map<String, String> _turkishNormalize = {
    'ı': 'i', 'İ': 'i', 'ğ': 'g', 'Ğ': 'g',
    'ü': 'u', 'Ü': 'u', 'ş': 's', 'Ş': 's',
    'ö': 'o', 'Ö': 'o', 'ç': 'c', 'Ç': 'c',
  };

  // Common stop words to filter (Turkish + English)
  static const Set<String> _stopWords = {
    // Turkish
    'bir', 'bu', 've', 'de', 'da', 'mi', 'mı', 'mu', 'mü',
    'ben', 'sen', 'o', 'biz', 'siz', 'onlar', 'için', 'ile',
    'ama', 'fakat', 'ancak', 'çok', 'az', 'daha', 'en',
    'gibi', 'kadar', 'nasıl', 'ne', 'neden', 'niçin',
    // English
    'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be',
    'been', 'being', 'have', 'has', 'had', 'do', 'does',
    'did', 'will', 'would', 'could', 'should', 'may',
    'might', 'must', 'shall', 'can', 'need', 'dare',
    'to', 'of', 'in', 'for', 'on', 'with', 'at', 'by',
    'from', 'as', 'into', 'through', 'during', 'before',
    'after', 'above', 'below', 'between', 'under', 'again',
    'further', 'then', 'once', 'here', 'there', 'when',
    'where', 'why', 'how', 'all', 'each', 'few', 'more',
    'most', 'other', 'some', 'such', 'no', 'nor', 'not',
    'only', 'own', 'same', 'so', 'than', 'too', 'very',
    'just', 'also', 'now', 'i', 'me', 'my', 'myself',
    'we', 'our', 'ours', 'ourselves', 'you', 'your',
    'yours', 'yourself', 'he', 'him', 'his', 'himself',
    'she', 'her', 'hers', 'herself', 'it', 'its', 'itself',
    'they', 'them', 'their', 'theirs', 'themselves',
    'what', 'which', 'who', 'whom', 'this', 'that',
    'these', 'those', 'am', 'and', 'but', 'if', 'or',
    'because', 'until', 'while', 'up', 'down', 'out',
    'off', 'over', 'about', 'against', 'both', 'any',
  };

  /// Normalize text for matching
  static String normalize(String text) {
    var result = text.toLowerCase().trim();
    
    // Normalize Turkish characters
    _turkishNormalize.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    
    // Remove extra whitespace
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    
    return result;
  }

  /// Tokenize text into words
  static List<String> tokenize(String text) {
    final normalized = normalize(text);
    // Split by non-alphanumeric characters
    return normalized
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.isNotEmpty && token.length > 1)
        .toList();
  }

  /// Remove stop words from tokens
  static List<String> removeStopWords(List<String> tokens) {
    return tokens.where((token) => !_stopWords.contains(token)).toList();
  }

  /// Get meaningful keywords from text
  static List<String> extractKeywords(String text) {
    final tokens = tokenize(text);
    return removeStopWords(tokens);
  }

  /// Clean text for comparison (remove punctuation, normalize)
  static String clean(String text) {
    var result = normalize(text);
    result = result.replaceAll(RegExp(r'[^\w\s]'), '');
    return result.trim();
  }

  /// Extract numbers from text
  static List<int> extractNumbers(String text) {
    final regex = RegExp(r'\d+');
    return regex.allMatches(text).map((m) => int.parse(m.group(0)!)).toList();
  }

  /// Check if text contains any of the words
  static bool containsAny(String text, List<String> words) {
    final normalized = normalize(text);
    for (final word in words) {
      if (normalized.contains(normalize(word))) {
        return true;
      }
    }
    return false;
  }

  /// Check if text contains all of the words
  static bool containsAll(String text, List<String> words) {
    final normalized = normalize(text);
    for (final word in words) {
      if (!normalized.contains(normalize(word))) {
        return false;
      }
    }
    return true;
  }

  /// Calculate word match score (0.0 - 1.0)
  static double wordMatchScore(String text, List<String> keywords) {
    if (keywords.isEmpty) return 0.0;
    
    final normalized = normalize(text);
    int matches = 0;
    
    for (final keyword in keywords) {
      if (normalized.contains(normalize(keyword))) {
        matches++;
      }
    }
    
    return matches / keywords.length;
  }
}
