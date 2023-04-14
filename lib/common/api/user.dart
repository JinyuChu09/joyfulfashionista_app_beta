import '../index.dart';

/// 用户 api
class UserApi {
  /// 注册
  static Future<bool> register(UserRegisterReq? req) async {
    var res = await WPHttpService.to.post(
      //'/users/register',
      '/wp-json/wc/v3/customers',

      data: req,
    );

    if (res.statusCode == 201) {
      return true;
    }
    return false;
  }

  /// login
  static Future<UserTokenModel> login(UserLoginReq? req) async {
    var res = await WPHttpService.to.get(
      //'/users/login',
      '/wp-json/wc/v3/customers',
      //data: req,
    );
    return UserTokenModel.fromJson(res.data);
  }

  /// Profile
  static Future<UserProfileModel> profile() async {
    var res = await WPHttpService.to.get(
      //'/users/me',
      '/wp-json/wc/v3/customers',
    );
    return UserProfileModel.fromJson(res.data);
  }

  /// 保存用户 billing address
  static Future<UserProfileModel> saveBillingAddress(Billing? req) async {
    var res = await WPHttpService.to.put(
      //'/users/me',
      '/wp-json/wc/v3/customers',
      data: {
        "billing": req,
      },
    );
    return UserProfileModel.fromJson(res.data);
  }

  /// 保存用户 shipping address
  static Future<UserProfileModel> saveShippingAddress(Shipping? req) async {
    var res = await WPHttpService.to.put(
      //'/users/me',
      '/wp-json/wc/v3/customers',
      data: {
        "shipping": req,
      },
    );
    return UserProfileModel.fromJson(res.data);
  }

  /// 大陆国家洲省列表
  static Future<List<ContinentsModel>> continents() async {
    var res = await WPHttpService.to.get(
      //'/users/continents',
      '/wp-json/wc/v3/customers/shipping/country',
    );

    List<ContinentsModel> continents = [];
    for (var item in res.data) {
      continents.add(ContinentsModel.fromJson(item));
    }
    return continents;
  }

  /// 保存用户 first name 、 last name 、 email
  static Future<UserProfileModel> saveBaseInfo(UserProfileModel req) async {
    var res = await WPHttpService.to.put(
      //'/users/me',
      '/wp-json/wc/v3/customers',
      data: {
        "first_name": req.firstName,
        "last_name": req.lastName,
        "email": req.email,
      },
    );
    return UserProfileModel.fromJson(res.data);
  }
}
