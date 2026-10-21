import 'package:marikina_market_mobile/core/shared/domain/enums/account_status.dart';
import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/vendor_profile.dart';

class User {
  final VendorProfile? vendor;
  final int userId;
  final String username;
  final String lastName;
  final String firstName;
  final String? middleName;
  final String email;
  final DateTime dateOfBirth;
  final String mobileNumber;
  final String address;
  final String houseNumber;
  final String street;
  final String barangay;
  final String city;
  final Role role;
  final AccountStatus status;
  final String? profileUrl;
  final DateTime createdAt;
  final bool mustChangePassword;

  User({
    this.vendor,
    required this.userId,
    required this.username,
    required this.lastName,
    required this.firstName,
    required this.middleName,
    required this.email,
    required this.dateOfBirth,
    required this.mobileNumber,
    required this.address,
    this.houseNumber = '',
    this.street = '',
    this.barangay = '',
    this.city = '',
    required this.role,
    required this.status,
    required this.profileUrl,
    required this.createdAt,
    required this.mustChangePassword,
  });
}
