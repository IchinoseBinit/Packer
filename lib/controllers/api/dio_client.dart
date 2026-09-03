import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/app_exception.dart';
import 'package:packer/controllers/api/model/custom_exception.dart';
import 'package:packer/controllers/extensions/debug_print_extension.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/router.dart';
import 'package:packer/enum/environment_config.dart';
import 'package:packer/features/views/auth/provider/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'error_handler.dart';

class DioClient {
  static final _dioClient = DioClient._();
  late final Dio _dio;
  static late String token;
  static late String refreshToken;
  late String baseUrl;

  factory DioClient() {
    return _dioClient;
  }

  DioClient._() {
    token = "";
    _dio = Dio();

    _initialize();
  }

  Future<void> _initialize() async {
    baseUrl = AppUrls.baseUrl;

    if (EnvironmentConfig.type == EnvironmentType.staging) {
      final prefs = await SharedPreferences.getInstance();
      final storedUrl = prefs.getString('customBaseUrl');
      if (storedUrl != null && storedUrl.isNotEmpty) {
        baseUrl = storedUrl;
      }
    }

    _dio.options = BaseOptions(baseUrl: baseUrl);

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          requestBody: true,
          logPrint: (object) => object.logDio(),
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.type == DioExceptionType.connectionError) {
            return handler.next(error);
          }

          if (token.isNotEmpty && error.response?.statusCode == 401) {
            var isSuccess = await AuthController().refreshToken();
            if (isSuccess is bool) {
              Map<String, String> headingWithToken = {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              };
              error.requestOptions.headers = headingWithToken;
              return handler.resolve(await _retry(error.requestOptions));
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  void updateBaseUrl(String newUrl) async {
    baseUrl = newUrl;
    _dio.options.baseUrl = newUrl;

    if (EnvironmentConfig.type == EnvironmentType.staging) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customBaseUrl', newUrl);
    }
  }

  final timeOutDuration = const Duration(seconds: 300);

  Future<Response> request({
    required RequestType requestType,
    required String url,
    dynamic body,
    dynamic queryParameters,
    dynamic headers,
  }) async {
    try {
      Response? resp;

      Map<String, String> heading = {
        'Content-Type': 'application/json',
        'Accept': '*/*',
      };

      Map<String, String> headingWithToken = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      switch (requestType) {
        case RequestType.get:
          resp = await _dio
              .get(
                url,
                options: Options(headers: heading),
                queryParameters: queryParameters,
              )
              .timeout(timeOutDuration);
          break;
        case RequestType.getWithToken:
          resp = await _dio
              .get(
                url,
                options: Options(headers: headingWithToken),
                queryParameters: queryParameters,
              )
              .timeout(timeOutDuration);
          break;
        case RequestType.post:
          resp = await _dio
              .post(
                url.trim(),
                data: jsonEncode(body),
                options: Options(headers: heading),
              )
              .timeout(timeOutDuration);
          break;
        case RequestType.postWithHeaders:
          resp = await _dio
              .post(
                url.trim(),
                data: jsonEncode(body),
                options: Options(headers: {...heading, ...headers}),
              )
              .timeout(timeOutDuration);
          break;
        case RequestType.postWithToken:
          resp = await _dio
              .post(
                url,
                data: jsonEncode(body),
                options: Options(headers: headingWithToken),
              )
              .timeout(timeOutDuration);
          break;
        case RequestType.postWithTokenFormData:
          resp = await _dio
              .post(
                url,
                data: body,
                options: Options(headers: headingWithToken),
              )
              .timeout(timeOutDuration);
          break;
        case RequestType.deleteWithToken:
          resp = await _dio
              .delete(
                url,
                data: jsonEncode(body),
                options: Options(headers: headingWithToken),
              )
              .timeout(timeOutDuration);
          break;
        case RequestType.patchWithToken:
          resp = await _dio
              .patch(
                url,
                data: jsonEncode(body),
                options: Options(headers: headingWithToken),
              )
              .timeout(timeOutDuration);
          break;
      }

      resp.log();
      return resp;
    } on DioException catch (ex) {
      ;

      final response = ex.response;
      final data = response?.data;

      // 401 – unauthorized token → go login
      if (token.isNotEmpty && response?.statusCode == 401) {
        navigateAndRemoveAllWithRouter(
          AppRouter.router,
          route: NavigationConstants.loginRoute,
        );
        throw LogoutException('Session expired');
      }

      // 403 → force logout token
      if (response?.statusCode == 403) {
        await AuthController().removeTokens();
        navigateAndRemoveAllWithRouter(
          AppRouter.router,
          route: NavigationConstants.loginRoute,
        );
        throw LogoutException(data is Map ? data['message']?.toString() : null);
      }

      ;

      // No internet
      if (ex.error is SocketException || ex.error is HttpException) {
        throw AppException(
          statusCode: null,
          message: ErrorHandler.errorMessage,
          json: data,
        );
      }

      // Debugging only
      if (kDebugMode && response?.statusCode == 502) {
        throw AppException(
          statusCode: 502,
          message: "Server in deployment phase",
          json: data,
        );
      }

      // Wrong data type
      if (data is String) {
        throw AppException(
          statusCode: response?.statusCode,
          message: ErrorHandler.errorMessage,
          json: data,
        );
      }

      // Django/DRF: non_field_errors
      if (data?["non_field_errors"] is List &&
          data["non_field_errors"].isNotEmpty) {
        throw AppException(
          statusCode: response?.statusCode,
          message: data["non_field_errors"][0],
          json: data,
        );
      }

      // Another token issue → force logout
      if (response?.statusCode == 401 &&
          data?["detail"]?.toString().toLowerCase().contains("token") == true) {
        throw LogoutException();
      }

      // Default API error message
      throw AppException(
        statusCode: response?.statusCode,
        message: data?["message"] ??
            data?["error"] ??
            data?["detail"]?.toString() ??
            ErrorHandler.errorMessage,
        json: data,
      );
    } catch (ex) {
      rethrow;
    }

    // } on DioException catch (ex) {
    //   if (token.isNotEmpty && ex.response?.statusCode == 401) {
    //     return navigateAndRemoveAllWithRouter(AppRouter.router,
    //         route: NavigationConstants.loginRoute);
    //   }
    //   if (ex.response?.statusCode == 403) {
    //     await AuthController().removeTokens();
    //     return navigateAndRemoveAllWithRouter(AppRouter.router,
    //         route: NavigationConstants.loginRoute);
    //   }

    //   if (ex.error is SocketException || ex.error is HttpException) {
    //     throw const SocketException(ErrorHandler.errorMessage);
    //   } else if (kDebugMode && ex.response?.statusCode == 502) {
    //     throw "Server in deployment phase";
    //   } else if (ex.response?.data == String) {
    //     throw ErrorHandler.errorMessage;
    //   } else if (ex.response?.data["non_field_errors"] != null &&
    //       ex.response?.data["non_field_errors"] is List) {
    //     throw ex.response?.data?["non_field_errors"][0] ??
    //         ErrorHandler.errorMessage;
    //   } else if (ex.response?.statusCode == 401 &&
    //       ex.response!.data!["detail"]
    //           .toString()
    //           .toLowerCase()
    //           .contains("token")) {
    //     throw LogoutException();
    //   }

    //   throw ex.response?.data?["message"] ??
    //       ex.response?.data?["error"] ??
    //       ex.response?.data?["detail"] ??
    //       ErrorHandler.errorMessage;
    // } catch (ex) {
    //   rethrow;
    // }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
