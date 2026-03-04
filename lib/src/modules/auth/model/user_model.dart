class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    // If the data is nested under 'user' or 'data'
    var realData = json['user'] ?? json['data'] ?? json;

    // If realData is a list, take the first element (common in some APIs)
    if (realData is List && realData.isNotEmpty) {
      realData = realData.first;
    }

    // Ensure we have a map to work with
    final Map<String, dynamic> data = (realData is Map<String, dynamic>)
        ? realData
        : json;

    return User(
      id: (data['id'] ?? data['_id'] ?? '').toString(),
      name:
          (data['name'] ??
                  data['username'] ??
                  data['fullName'] ??
                  data['display_name'] ??
                  '')
              .toString(),
      email: (data['email'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email};
  }
}
