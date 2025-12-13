class Doctor {
  Doctor({
    required this.name,
    required this.title,
    required this.field,
    required this.location,
    required this.imageAsset,
    this.patients = 0,
    this.years = 0,
    this.rating = 0.0,
    this.reviews = 0,
    this.isFavorite = false,
  });

  final String name;
  final String title;
  final String field;
  final String location;
  final String imageAsset;
  int patients;
  int years;
  double rating;
  int reviews;
  bool isFavorite;
}