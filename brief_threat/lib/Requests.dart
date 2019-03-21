import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Tokens/models/RefreshToken.dart';
import 'Tokens/models/AccessToken.dart';

class Requests {
  static Future<RefreshToken> login(String _username, String _password) async {
    String credentialsAsJson =jsonEncode({"username": _username, "password": _password});

    final response = await http.post(
      'https://briefthreat.nul.ie//api/v1/auth/login', 
      headers: {"Content-Type": "application/json"},
      body: credentialsAsJson);

    if (response.statusCode == 200) {
      //parse the JSON to get the refresh key
      return RefreshToken.fromJson(jsonDecode(response.body));
    } 

    // authentification failed
    return null;
  }

  // returns true if user is an admin
  static Future<bool> isUserAdmin(String accessToken) async {
    final response = await http.get(
      'https://briefthreat.nul.ie/api/v1/auth/login', 
      headers: {"Authorization": "Bearer $accessToken"});

    if (response.statusCode == 200) {
      Map<String, dynamic> json =jsonDecode(response.body);
      // success, return access token from JSON
      return json['is_admin'];
    } 

    // request failed
    return false;
  }

  static Future<AccessToken> generateAccessToken(String refreshToken) async {
    final response = await http.post(
      'https://briefthreat.nul.ie/api/v1/auth/token', 
      headers: {"Authorization": "Bearer $refreshToken"});

    if (response.statusCode == 200) {
      // success, return access token from JSON
      return AccessToken.fromJson(jsonDecode(response.body));
    } 

    // request failed
    return null;
  }  

  static Future<int> postForm(String accessToken, String user, String repName, String course, double amount, String receipt, DateTime date, String paymentMethod) async {
    String dataAsJson =jsonEncode({
      "customer_name" : user,   
      "course" : course,
      "payment_method" : paymentMethod.toLowerCase(),
      "receipt" : receipt,
      "time" : (date.millisecondsSinceEpoch / 1000).round(),
      "amount" : amount
      });

    final response = await http.post(
      'https://briefthreat.nul.ie/api/v1/form', 
      headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"},
      body: dataAsJson);

    if (response.statusCode == 200) {
      // success, return id
      return jsonDecode(response.body)['id'];
    } 

    // request failed
    return 0;
  }

  static Future<bool> deleteToken(String token) async {
    final response = await http.delete(
      'https://briefthreat.nul.ie/api/v1/auth/token', 
      headers: {"Authorization": "Bearer $token"});

    if(response.statusCode == 204) {
      return true;
    }

    return false;
  }

  // register new user, returns boolean status reflecting success / failure
  static Future<String> register(String username, String email, bool isAdmin, String firstName, String lastName, String accessToken) async {
    String dataAsJson =jsonEncode({"username": username, "email": email, "is_admin":isAdmin, "first_name":firstName, "last_name":lastName});

    final response = await http.post(
      'https://briefthreat.nul.ie/api/v1/auth/register', 
      headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"},
      body: dataAsJson);

    return response.statusCode == 204 ? null : jsonDecode(response.body)['message'];
  }  
}