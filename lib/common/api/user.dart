import 'dart:io';

import 'package:joyfulfashionista_app/test.dart';

import '../index.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import '../services/user_manager.dart';
String basicAuth = 'Basic ' +
    base64Encode(utf8.encode(
        'ck_79e2c4c70e87dac66405834e972982eb7b02feb5:cs_fb0e4132784e31f0c5ca87ddc2529ecf1d59ca6f'));


/// 用户 api
class UserApi {

  final UserManager userManager = UserManager();

  /// 注册
  static Future<bool> register(UserRegisterReq? req) async {
    final String apiUrl = 'https://teamjoyful.buzz/wp-json/wc/v3/customers';

    String requestBody = json.encode(req);
    print('Request Body: $requestBody');
    String? username = req!.username;
    String? password = req!.password;
    var res = await http.post(
          Uri.parse(apiUrl),
          body: json.encode(req),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': basicAuth
          }
          );

    print('Response Status: ${res.statusCode}');
    print('Response Body: ${res.body}');

    if (res.statusCode == 201) {
      login(username!, password!);
           return true;
         }
         return false;
  }


  static Future<void> login(String username, String password) async {

    final response = await http.post(
      Uri.parse('https://teamjoyful.buzz/wp-json/jwt-auth/v1/token'),
      body: {
        'username': username,
        'password': password,
      },
    );

    // Save username and password
    UserApi().userManager.setUsername('$username');
    UserApi().userManager.setPassword('$password');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      String userToken = jsonResponse['token'];
      await UserService.to.storeToken(username, userToken);
      await UserService.to.getProfile();
      // print('token $token');
      // print(jsonResponse);
      Loading.success();
      Get.back(result: true);
    } else {
      print('Status code: ${response.statusCode}');
      throw Exception('Failed to login');

    }
  }

  // FIXME: fix images upload
  /// Upload product
  static Future<void> uploadProduct(List<String> imagesURL, String title, String description, String color, String price, String size, int tag) async {
    // WooCommerce API endpoint for products
    String apiUrl = Constants.wpApiBaseUrl + "/wp-json/wc/v3/products";

    // JWT token
    String? jwtToken = await UserService().getToken("tester");

    // Create headers with JWT token
    Map<String, String> headers = {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    };

    // Create the images list for WooCommerce
    List<Map<String, String>> wooImages = imagesURL.map((url) => {"src": url}).toList();

    // Build the request body with product info and images
    Map<String, dynamic> body = {
      'name': title,
      'description': description,
      'regular-price' : price,
      'attributes' : [
        {
          'id' : 1,
          'name' : 'Color',
          'position' : 1,
          'visible' : true,
          'options' : color
        },
        {
          'id' : 2,
          'name' : 'Size',
          'position' : 4,
          'visible' : true,
          'options' : size
        }
      ],
      'categories' : [
        {
          'id' : tag
        }
      ],
      'images': wooImages,
    };

    // Send the POST request
    var response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(body)
    );

    // Check for response status code
    if (response.statusCode == 201) {
      print('Product uploaded successfully');
      print('Product ID: ${json.decode(response.body)['id']}');
    } else {
      print('Failed to upload product');
      print('Response: ${response.body}');
    }
  }


  /// upload to imgur
  final String _clientID = '333783c2f7a8750';

  Future<String?> uploadToImgur(File image) async {
    final request = http.MultipartRequest('POST', Uri.parse('https://api.imgur.com/3/upload'));
    request.headers['Authorization'] = 'Client-ID $_clientID';

    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['data']['link'] as String;
    } else {
      print('Failed to upload image to Imgur: ${response.body}');
      return null;
    }
  }

  /// get id
  static Future<int> getSelfId(String token) async{
    final response = await http.get(
        Uri.parse(Constants.wpApiBaseUrl + '/wp-json/wp/v2/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        }
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse.isNotEmpty) {
        return jsonResponse["id"];
      } else {
        throw Exception("User not found");
      }
    } else {
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception("Failed to login user");
    }
  }


  /// Profile

  static Future<UserProfileModel> profile(String token) async{
    int id = await UserApi.getSelfId(token);
    String? testerToken = await UserService.to.fetchJwtToken('tester', '123456');
    final response = await http.get(
        Uri.parse(Constants.wpApiBaseUrl + '/wp-json/wc/v3/customers/$id'),
        headers: {
          'Authorization': 'Bearer $testerToken',
        }
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse.isNotEmpty) {
        // print(id);
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return UserProfileModel.fromJson(jsonResponse);
        // print(jsonResponse["id"]);
        // return jsonResponse["id"];
      } else {
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception("User not found");
      }
    } else {
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception("Failed to login user");
    }
  }


  /// 保存用户 billing address
  static Future<UserProfileModel> saveBillingAddress(Billing? req) async {

      String username = UserApi().userManager.getUsername();
      String? token = await UserService.to.getToken('$username');
      int id = await UserApi.getSelfId(token!);

      String? testerToken = await UserService.to.fetchJwtToken('tester', '123456');
      var body = jsonEncode({
        'billing': req?.toJson(),
      });

      var res = await http.put(
          Uri.parse(Constants.wpApiBaseUrl + '/wp-json/wc/v3/customers/$id'),
          body: body,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $testerToken',
          }
      );

      print(res.statusCode);
      return UserProfileModel.fromJson(jsonDecode(res.body));

  }

  /// 保存用户 shipping address
  static Future<UserProfileModel> saveShippingAddress(Shipping? req) async {

    String username = UserApi().userManager.getUsername();
    String? token = await UserService.to.getToken('$username');
    int id = await UserApi.getSelfId(token!);

    String? testerToken = await UserService.to.fetchJwtToken('tester', '123456');
    var body = jsonEncode({
      'shipping': req?.toJson(),
    });
    
    var res = await http.put(
      Uri.parse(Constants.wpApiBaseUrl + '/wp-json/wc/v3/customers/$id'),
      body: body,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $testerToken',
      }
    );
    print(res.statusCode);
    return UserProfileModel.fromJson(jsonDecode(res.body));
  }

  /// 大陆国家洲省列表
  static Future<List<ContinentsModel>> continents() async {
    String? token = await UserService.to.fetchJwtToken('tester', '123456');
    var res = await http.get(
        Uri.parse(Constants.wpApiBaseUrl +'/wp-json/wc/v3/data/countries'),
        headers: {
          'Authorization': 'Bearer $token',
        }
    );

    List<ContinentsModel> continents = [];
    for (var item in jsonDecode(res.body)) {
      continents.add(ContinentsModel.fromJson(item));
    }
    return continents;
  }

  /// 保存用户 first name 、 last name 、 email
  static Future<UserProfileModel> saveBaseInfo(UserProfileModel req) async {
    var res = await http.put(
        Uri.parse(Constants.wpApiBaseUrl + '/wp-json/wc/v3/customers'),
      body: {
        "first_name": req.firstName,
        "last_name": req.lastName,
        "email": req.email,
      },
    );
    return UserProfileModel.fromJson(jsonDecode(res.body));
  }
}


void main() async{
  // String email = 'tom@tom.com';
  String username = 'tom';
  String password = '8h76\$PlAb*CK%vz%kK#wPxvh';
  // UserApi api = UserApi();

  // String token =  await UserApi.login(username, password);
  // print(token);

  // int? id = await getSelfId(token);
  print("hello");
  //
  // await profile(token, id);

}