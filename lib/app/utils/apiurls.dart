class Apiurls {
  static String baseUrl = 'https://app-test343434343434.onrender.com';

  // auth
  static String register = '$baseUrl/api/auth/register';
  static String login = '$baseUrl/api/auth/login';

  // blogs
  static String blogs = '$baseUrl/api/blogs';
  static String myBlogs = '$baseUrl/api/blogs/my';
  static String blogById(String id) => '$baseUrl/api/blogs/$id';
  static String react(String id) => '$baseUrl/api/blogs/$id/react';
  static String categories = '$baseUrl/api/blogs/categories';

  // upload
  static String uploadSingle = '$baseUrl/api/upload/image';
  static String deleteFile = '$baseUrl/api/upload/delete';
}
