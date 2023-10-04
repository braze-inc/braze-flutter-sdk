import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class JwtGenerator {
  static const String SdkAuthTokenEndpoint =
      "https://us-central1-jwt-responder.cloudfunctions.net/getToken";

  /// Returns a JWT associated with the Braze's public key on the dashboard for
  /// the App Group of this sample app.
  static Future<String?> create(String userId) async {
    final body = {
      'data': {
        'user_id': userId,
      }
    };
    var encodedBody = json.encode(body);
    var header = {
      "Content-Type": "application/json",
      "Accept": "application/json"
    };

    try {
      final response = await http.post(Uri.parse(SdkAuthTokenEndpoint),
          body: encodedBody, headers: header);
      var responseJson = json.decode(response.body.toString());
      var token = responseJson["data"]["token"];

      print('$userId is using this token for SDK Auth: $token');
      return token;
    } catch (e) {
      print('Error fetching JWT: $e');
      return null;
    }
  }
}
