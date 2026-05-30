class Client {
  final int? id;
  final String name;
  final String plant;

  Client({this.id, required this.name, required this.plant});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'plant': plant,
      };

  factory Client.fromMap(Map<String, dynamic> map) => Client(
        id: map['id'],
        name: map['name'],
        plant: map['plant'],
      );
}
