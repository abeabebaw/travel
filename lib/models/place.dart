class Place {
  int? id;
  String name;
  String imagePath;

  Place({this.id, required this.name, required this.imagePath});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'imagePath': imagePath};
  }

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      id: map['id'],
      name: map['name'],
      imagePath: map['imagePath'],
    );
  }
}