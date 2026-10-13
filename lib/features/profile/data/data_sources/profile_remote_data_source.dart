import 'dart:io';

import 'package:dio/dio.dart';
import 'package:marikina_market_mobile/core/errors/api_error_message.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/edit_profile_params.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/utils/file_compressor_util.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> updateUser(EditProfileParams params);

  Future<void> changeUserPassword(
    int userId,
    String currentPassword,
    String newPassword,
    String confirmNewPassword,
  );

  Future<UserModel> changePhoto(XFile file);
  Future<UserModel> removePhoto();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient apiClient;

  ProfileRemoteDataSourceImpl(this.apiClient);

  @override
  Future<UserModel> updateUser(EditProfileParams params) async {
    try {
      final date = params.dateOfBirth;
      final response = await apiClient.post(
        '/User/profile',
        options: Options(contentType: Headers.jsonContentType),
        data: {
          'first_name': params.firstName,
          'middle_name': params.middleName,
          'last_name': params.lastName,
          'date_of_birth':
              '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'email': params.email,
          'phone_number': params.phoneNumber,
          'house_number': params.houseNumber,
          'street': params.street,
          'barangay': params.barangay,
          'city': params.city,
        },
      );
      final data = response.data;
      if (data is! Map<String, Object?>) throw const FormatException();
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      final message = ApiErrorMessage.fromBody(e.response?.data) ?? '';
      switch (e.response?.statusCode) {
        case 400:
          throw ValidationException(message);
        case 401:
          throw TokenExpiredException(message);
        case 403:
          throw UnauthorizedException(message);
        case 404:
          throw NotFoundException(message);
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException(message);
      }
      // ApiClient cancels a request when an in-flight session refresh fails.
      if (e.type == DioExceptionType.cancel &&
          e.error == 'Authentication refresh failed.') {
        throw TokenExpiredException(message);
      }
      throw ServerException(message);
    } on FormatException {
      throw ServerException('');
    } on TypeError {
      throw ServerException('');
    } on ArgumentError {
      throw ServerException('');
    }
  }

  @override
  Future<void> changeUserPassword(
    int userId,
    String currentPassword,
    String newPassword,
    String confirmNewPassword,
  ) async {
    try {
      await apiClient.post(
        '/auth/change-password',
        data: {
          'user_id': userId,
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_new_password': confirmNewPassword,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw UnauthorizedException(
          e.response?.data ??
              'Failed to change password. Please try again later.',
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }
      throw ServerException('Something went wrong. Please try again later');
    }
  }

  @override
  Future<UserModel> changePhoto(XFile file) async {
    try {
      final compressedPhoto = await compressImage(File(file.path));

      final multipartFile = await MultipartFile.fromFile(
        compressedPhoto.path,
        filename: file.name,
      );

      final formData = FormData.fromMap({'file': multipartFile});

      final response = await apiClient.put(
        '/user/change-photo',
        data: formData,
      );

      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw UnauthorizedException(
          e.response?.data ?? 'Unable to change photo.',
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }

      throw ServerException('Something went wrong. Please try again later');
    }
  }

  @override
  Future<UserModel> removePhoto() async {
    try {
      final response = await apiClient.put('/user/remove-photo');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw UnauthorizedException(
          e.response?.data ?? 'Unable to remove photo.',
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }

      throw ServerException('Something went wrong. Please try again later');
    }
  }
}
