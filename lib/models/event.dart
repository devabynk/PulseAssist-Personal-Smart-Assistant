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
    final String date = json['dates']?['start']?['localDate'] ?? '';
    
    var venue = 'Adres yok';
    if (json['_embedded'] != null &&
        json['_embedded']['venues'] != null &&
        (json['_embedded']['venues'] as List).isNotEmpty) {
      venue = json['_embedded']['venues'][0]['name'] ?? 'Adres yok';
    }

    var imageUrl = '';
    if (json['images'] != null && (json['images'] as List).isNotEmpty) {
      // Find a suitable image or just take the first one
      imageUrl = json['images'][0]['url'] ?? '';
    }

    // Description is often in 'info' or missing
    final String description = json['info'] ?? json['pleaseNote'] ?? '';

    return Event(
      title: title,
      date: date,
      location: venue,
      description: description,
      imageUrl: imageUrl,
      link: json['url'] ?? '',
    );
  }
}
