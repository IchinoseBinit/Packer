
import 'package:flutter/material.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/firebase_opt/fcm_api.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/secure_storage_helper.dart';
import 'package:packer/features/views/auth/model/token.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/secure_storage_constants.dart';

class AuthController {
  Future validateLogin(
      BuildContext context, String username, String password) async {
    try {
      // Sending POST request to login endpoint
      final body = {
        'username': username,
        'password': password,
      };
      final response = await DioClient().request(
        requestType: RequestType.post,
        url: AppUrls.loginUrl,
        body: body,
      );

      final token = Token.fromMap(response.data);
      await saveToken(token);
      FCMApi().postFcmToken();

      return true;
    } catch (ex) {
      // Server error
      print('Error: $ex');
      return ex.toString();
    }
  }

  Future logout() async {
    final body = {
      "refresh": DioClient.refreshToken,
    };
    try {
      final otpResponse = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.logoutUrl,
        body: body,
      );


      if (otpResponse.statusCode == 200) {
        await removeTokens();
        return true;
      } else {
        throw otpResponse.data["message"];
      }
    } catch (e) {
      return e.toString();
    }
  }

  saveToken(Token token) async {
    await SecureStorageHelper().write(
      key: SecureStorageConstants.accessTokenKey,
      value: token.accessToken,
    );
    await SecureStorageHelper().write(
      key: SecureStorageConstants.refreshTokenKey,
      value: token.refreshToken,
    );

    DioClient.token = token.accessToken;
    DioClient.refreshToken = token.refreshToken;
  }

  removeTokens() async {
    await SecureStorageHelper()
        .remove(key: SecureStorageConstants.accessTokenKey);
    await SecureStorageHelper()
        .remove(key: SecureStorageConstants.refreshTokenKey);
    DioClient.token = "";
    DioClient.refreshToken = "";
  }

  Future refreshToken() async {
    final body = {"refresh": DioClient.refreshToken};
    try {
      final otpResponse = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.refreshTokenUrl,
        body: body,
      );

      if (otpResponse.statusCode == 200) {
        final token = Token.fromMap(otpResponse.data);
        await saveToken(token);
        return true;
      } else {
        throw otpResponse.data["message"];
      }
    } catch (e) {
      print(e);
      return e.toString();
    }
  }
}
