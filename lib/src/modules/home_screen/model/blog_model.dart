class BlogRequestModel {
  final String title;
  final String description;
  final List<String> tags;
  final String category;
  final String? image;

  BlogRequestModel({
    required this.title,
    required this.description,
    required this.tags,
    required this.category,
    this.image,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'tags': tags,
    'category': category,
    'image': image,
  };
}

class BlogResponseModel {
  final bool success;
  final String message;
  final BlogData? data;

  BlogResponseModel({required this.success, required this.message, this.data});

  factory BlogResponseModel.fromJson(Map<String, dynamic> json) {
    return BlogResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? BlogData.fromJson(json['data']) : null,
    );
  }
}

class BlogData {
  final String? id;
  final String title;
  final String description;
  final List<String> tags;
  final String category;
  final String? image;
  final String? createdAt;
  final String? authorName;
  final String? authorImage;
  final Map<String, int> reactions;

  BlogData({
    this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.category,
    this.image,
    this.createdAt,
    this.authorName,
    this.authorImage,
    this.reactions = const {},
  });

  factory BlogData.fromJson(Map<String, dynamic> json) {
    return BlogData(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'] ?? 'Others',
      image: json['image'] ?? json['imageUrl'],
      createdAt: json['createdAt'],
      authorName: json['authorName'] ?? json['author'] ?? 'Author',
      authorImage: json['authorImage'],
      reactions: Map<String, int>.from(json['reactions'] ?? {}),
    );
  }
}
