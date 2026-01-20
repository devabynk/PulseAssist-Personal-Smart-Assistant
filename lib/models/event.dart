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
      imageUrl: json['image'] ?? '',
      link: json['link'] ?? '',
    );
  }
}
