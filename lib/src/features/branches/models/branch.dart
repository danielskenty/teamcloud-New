class Branch {
  final String id;
  final String name;
  final String address;
  final bool active;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    this.active = true,
  });

  factory Branch.fromMap(String id, Map<String, dynamic> data) {
    return Branch(
      id: id,
      name: data['name'] as String? ?? 'Unnamed branch',
      address: data['address'] as String? ?? '',
      active: data['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'active': active,
    };
  }
}
