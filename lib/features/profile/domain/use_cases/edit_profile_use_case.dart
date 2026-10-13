import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/usecases/usecase.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/edit_profile_params.dart';

class EditProfileUseCase extends UseCase<User, EditProfileParams> {
  final ProfileRepository _repository;
  EditProfileUseCase(this._repository);

  @override
  Future<Result<User>> call(EditProfileParams params) async {
    if ([
      params.firstName,
      params.lastName,
      params.email,
      params.phoneNumber,
      params.houseNumber,
      params.street,
      params.barangay,
      params.city,
    ].any((value) => value.trim().isEmpty)) {
      return Result.failure(
        const ValidationFailure('Complete all required profile fields.'),
      );
    }
    for (final entry in {
      'First name': (params.firstName, 100),
      'Middle name': (params.middleName ?? '', 100),
      'Last name': (params.lastName, 100),
      'Email': (params.email, 255),
      'House number': (params.houseNumber, 50),
      'Street': (params.street, 100),
      'Barangay': (params.barangay, 100),
      'City': (params.city, 100),
    }.entries) {
      final (value, limit) = entry.value;
      if (value.trim().length > limit) {
        return Result.failure(
          ValidationFailure('${entry.key} must not exceed $limit characters.'),
        );
      }
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(params.email.trim())) {
      return Result.failure(
        const ValidationFailure('Enter a valid email address.'),
      );
    }
    if (!RegExp(r'^09[0-9]{9}$').hasMatch(params.phoneNumber.trim())) {
      return Result.failure(
        const ValidationFailure(
          'Phone number must have 11 digits and start with 09.',
        ),
      );
    }
    final now = DateTime.now();
    final birthDate = DateTime(
      params.dateOfBirth.year,
      params.dateOfBirth.month,
      params.dateOfBirth.day,
    );
    if (birthDate.isAfter(DateTime(now.year, now.month, now.day))) {
      return Result.failure(
        const ValidationFailure('Birth date cannot be in the future.'),
      );
    }
    final middleName = params.middleName?.trim();
    return _repository.updateUserInfo(
      EditProfileParams(
        firstName: params.firstName.trim(),
        middleName: middleName == null || middleName.isEmpty
            ? null
            : middleName,
        lastName: params.lastName.trim(),
        dateOfBirth: birthDate,
        email: params.email.trim(),
        phoneNumber: params.phoneNumber.trim(),
        houseNumber: params.houseNumber.trim(),
        street: params.street.trim(),
        barangay: params.barangay.trim(),
        city: params.city.trim(),
      ),
    );
  }
}
