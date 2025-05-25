import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// Custom exception for better error handling
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class ApiService {
  // Configurable base URL (replace with environment variable in production)
  static const String baseUrl = 'http://localhost:3000'; // TODO: Use env variables

  Future<bool> signup(String username, String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Failed to sign up', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw ApiException('Network error: Please check your connection');
      }
      throw ApiException('Signup failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password, String selectedRole) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Failed to log in', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw ApiException('Network error: Please check your connection');
      }
      throw ApiException('Login failed: ${e.toString()}');
    }
  }

  Future<bool> uploadPlace(String title, String description, String location, Uint8List imageBytes, String imageName, int userId, double rating) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/add-place'));
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['location'] = location;
      request.fields['userId'] = userId.toString();
      request.fields['rating'] = rating.toString();
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageName,
        contentType: _getContentType(imageName),
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(responseBody);
        throw ApiException(errorData['error'] ?? 'Failed to add place', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw ApiException('Network error: Please check your connection');
      }
      throw ApiException('Failed to add place: ${e.toString()}');
    }
  }

  Future<bool> addAgency(String name, String description, String contact, Uint8List? imageBytes, String? imageName, int userId) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/add-agency'));
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['contact'] = contact;
      request.fields['userId'] = userId.toString();
      if (imageBytes != null && imageName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName,
          contentType: _getContentType(imageName),
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(responseBody);
        throw ApiException(errorData['error'] ?? 'Failed to add agency', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw ApiException('Network error: Please check your connection');
      }
      throw ApiException('Failed to add agency: ${e.toString()}');
    }
  }

  Future<bool> addTourSchedule(int agencyId, int placeId, String tourDate, double price, String description, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add-tour-schedule'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'agencyId': agencyId,
          'placeId': placeId,
          'tourDate': tourDate,
          'price': price,
          'description': description,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Failed to add tour schedule', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw ApiException('Network error: Please check your connection');
      }
      throw ApiException('Failed to add tour schedule: ${e.toString()}');
    }
  }

  Future<bool> deletePlace(int placeId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete-place/$placeId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Failed to delete place', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw ApiException('Network error: Please check your connection');
      }
      throw ApiException('Failed to delete place: ${e.toString()}');
    }
  }

  Future<bool> likePlace(int placeId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/like-place'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'placeId': placeId,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Failed to like/unlike place', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw ApiException('Network error: Please check your connection');
      }
      throw ApiException('Failed to like/unlike place: ${e.toString()}');
    }
  }

  Future<bool> checkLikeStatus(int placeId, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/like-status/$placeId/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isLiked'] ?? false;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Failed to check like status', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw ApiException('Network error: Please check your connection');
      }
      throw ApiException('Failed to check like status: ${e.toString()}');
    }
  }

  Future<bool> addComment(int placeId, String comment, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add-comment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'placeId': placeId,
          'comment': comment,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Failed to add comment', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw ApiException('Network error: Please check your connection');
      }
      throw ApiException('Failed to add comment: ${e.toString()}');
    }
  }

  Future<bool> addCommentReply(int commentId, String reply, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add-comment-reply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'commentId': commentId,
          'reply': reply,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Failed to add reply', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw ApiException('Network error: Please check your connection');
      }
      throw ApiException('Failed to add reply: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPlaces() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/places'));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw ApiException('Failed to fetch places', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw ApiException('Network error: Please check your connection');
      }
      throw ApiException('Failed to fetch places: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchTopPlaces() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/top-places'));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw ApiException('Failed to fetch top places', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw ApiException('Network error: Please check your connection');
      }
      throw ApiException('Failed to fetch top places: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAgencies() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/agencies'));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw ApiException('Failed to fetch agencies', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw ApiException('Network error: Please check your connection');
      }
      throw ApiException('Failed to fetch agencies: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchTourSchedules(int agencyId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tour-schedules/$agencyId'));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw ApiException('Failed to fetch tour schedules', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw ApiException('Network error: Please check your connection');
      }
      throw ApiException('Failed to fetch tour schedules: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchComments(int placeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/comments/$placeId'));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw ApiException('Failed to fetch comments', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw ApiException('Network error: Please check your connection');
      }
      throw ApiException('Failed to fetch comments: ${e.toString()}');
    }
  }

  MediaType _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}