import 'package:marikina_market_mobile/core/shared/domain/enums/account_status.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';
import 'package:marikina_market_mobile/features/auth/data/models/vendor_profile_model.dart';

class UserModel {
  final VendorProfileModel? vendor;
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

  UserModel({
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
    required this.createdAt,
    required this.mustChangePassword,
    required this.profileUrl,
  });

  factory UserModel.fromJson(Map<String, Object?> json) {
    return UserModel(
      vendor: json['vendor'] is Map<String, Object?>
          ? VendorProfileModel.fromJson(json['vendor'] as Map<String, Object?>)
          : null,
      userId: (json['userId'] ?? json['user_id']) as int,
      username: json['username'] as String,
      lastName: (json['lastName'] ?? json['last_name']) as String,
      firstName: (json['firstName'] ?? json['first_name']) as String,
      middleName: (json['middleName'] ?? json['middle_name']) as String?,
      email: json['email'] as String,
      dateOfBirth: DateTime.parse(
        (json['dateOfBirth'] ?? json['date_of_birth']) as String,
      ),
      mobileNumber: (json['phoneNumber'] ?? json['mobile_number']) as String,
      houseNumber:
          (json['houseNumber'] ?? json['house_number']) as String? ?? '',
      street: json['street'] as String? ?? '',
      barangay: json['barangay'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json.containsKey('address')
          ? json['address'] as String
          : '${(json['houseNumber'] ?? json['house_number']) as String} ${json['street'] as String} ${json['barangay'] as String} ${json['city'] as String} City',
      role: Role.fromValue(switch (json['role'] as String) {
        'Enforcer' when json.containsKey('user_id') => 'MarketEnforcer',
        'Vendor' when json.containsKey('user_id') => 'MarketVendor',
        final role => role,
      }),
      status: AccountStatus.fromValue(
        json['status'] == 'Inactive' ? 'Deactivated' : json['status'] as String,
      ),
      profileUrl: (json['profileUrl'] ?? json['profile_url']) as String?,
      createdAt: DateTime.parse(
        (json['createdAt'] ?? json['created_at']) as String,
      ),
      mustChangePassword:
          (json['mustChangedPassword'] ?? json['must_changed_password'])
              as bool,
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (vendor != null) 'vendor': vendor!.toJson(),
      'user_id': userId,
      'username': username,
      'last_name': lastName,
      'first_name': firstName,
      'middle_name': middleName,
      'email': email,
      'date_of_birth':
          '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}',
      'mobile_number': mobileNumber,
      'address': address,
      'house_number': houseNumber,
      'street': street,
      'barangay': barangay,
      'city': city,
      'role': role.value,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'profile_url': profileUrl,
      'must_changed_password': mustChangePassword,
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      vendor: user.vendor == null ? null : VendorProfileModel(user.vendor!),
      userId: user.userId,
      username: user.username,
      lastName: user.lastName,
      firstName: user.firstName,
      middleName: user.middleName,
      email: user.email,
      dateOfBirth: user.dateOfBirth,
      mobileNumber: user.mobileNumber,
      address: user.address,
      houseNumber: user.houseNumber,
      street: user.street,
      barangay: user.barangay,
      city: user.city,
      role: user.role,
      status: user.status,
      profileUrl: user.profileUrl,
      createdAt: user.createdAt,
      mustChangePassword: user.mustChangePassword,
    );
  }

  User toEntity() {
    return User(
      vendor: vendor?.toEntity(),
      userId: userId,
      username: username,
      lastName: lastName,
      firstName: firstName,
      middleName: middleName,
      email: email,
      dateOfBirth: dateOfBirth,
      mobileNumber: mobileNumber,
      address: address,
      houseNumber: houseNumber,
      street: street,
      barangay: barangay,
      city: city,
      role: role,
      status: status,
      profileUrl: profileUrl,
      createdAt: createdAt,
      mustChangePassword: mustChangePassword,
    );
  }
}
