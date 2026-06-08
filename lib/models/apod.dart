class Apod {
  final String title;
  final String explanation;
  final String url;
  final String? hdurl;
  final String date;
  final String mediaType;

  Apod({
    required this.title,
    required this.explanation,
    required this.url,
    this.hdurl,
    required this.date,
    required this.mediaType,
  });

  factory Apod.fromJson(Map<String, dynamic> json) {
    return Apod(
      title: json['title'] as String,
      explanation: json['explanation'] as String,
      url: json['url'] as String,
      hdurl: json['hdurl'] as String?,
      date: json['date'] as String,
      mediaType: json['media_type'] as String,
    );
  }
}
