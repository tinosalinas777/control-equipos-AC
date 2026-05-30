class Equipment {
  final int? id;
  final int clientId;
  final int number;
  final String location;
  final String capacity;
  final String type;
  final String refrigerant;
  final String brand;

  Equipment({
    this.id,
    required this.clientId,
    required this.number,
    required this.location,
    required this.capacity,
    required this.type,
    required this.refrigerant,
    required this.brand,
  });

  String get displayName => 'Eq. $number - $location';

  Map<String, dynamic> toMap() => {
        'id': id,
        'client_id': clientId,
        'number': number,
        'location': location,
        'capacity': capacity,
        'type': type,
        'refrigerant': refrigerant,
        'brand': brand,
      };

  factory Equipment.fromMap(Map<String, dynamic> map) => Equipment(
        id: map['id'],
        clientId: map['client_id'],
        number: map['number'],
        location: map['location'],
        capacity: map['capacity'],
        type: map['type'],
        refrigerant: map['refrigerant'],
        brand: map['brand'],
      );
}
