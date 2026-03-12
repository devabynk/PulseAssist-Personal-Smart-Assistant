class Event {
  final String title;
  final String description;
  final String date;
  final String location;
  final String imageUrl;
  final String link;

  Event({
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.imageUrl,
    required this.link,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      location: json['location'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      link: json['link'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'location': location,
      'imageUrl': imageUrl,
      'link': link,
    };
  }

  factory Event.fromTicketmaster(Map<String, dynamic> json) {
    final String title = json['name'] ?? 'Etkinlik';

    // Date + time
    final date = (json['dates']?['start']?['localDate'] ?? '') as String;
    final time = (json['dates']?['start']?['localTime'] ?? '') as String;
    final dateTime = (date.isNotEmpty && time.isNotEmpty)
        ? '$date $time'
        : date;

    // Full venue: "Venue Name, Address, City"
    var location = '';
    if (json['_embedded']?['venues'] is List &&
        (json['_embedded']['venues'] as List).isNotEmpty) {
      final v = json['_embedded']['venues'][0] as Map<String, dynamic>;
      final venueName = v['name']?.toString() ?? '';
      final venueAddress = v['address']?['line1']?.toString() ?? '';
      final venueCity = v['city']?['name']?.toString() ?? '';

      final parts = <String>[];
      if (venueName.isNotEmpty) parts.add(venueName);
      if (venueAddress.isNotEmpty && venueAddress != venueName) parts.add(venueAddress);
      if (venueCity.isNotEmpty) parts.add(venueCity);
      location = parts.join(', ');
    }

    // Best image: prefer 16:9 ratio at least 640px wide, fall back to first
    var imageUrl = '';
    if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      final images = json['images'] as List;
      final wide = images.firstWhere(
        (img) =>
            img['ratio'] == '16_9' && ((img['width'] ?? 0) as int) >= 640,
        orElse: () => images.first,
      );
      imageUrl = wide['url']?.toString() ?? '';
    }

    final description = json['info']?.toString() ??
        json['pleaseNote']?.toString() ??
        '';

    return Event(
      title: title,
      date: dateTime,
      location: location,
      description: description,
      imageUrl: imageUrl,
      link: json['url']?.toString() ?? '',
    );
  }
}
