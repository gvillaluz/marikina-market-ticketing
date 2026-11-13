import 'package:marikina_market_mobile/core/shared/domain/enums/account_status.dart';

class Userprofile {
  final int userId;
  final String username;
  final String firstName;
  final String? middleName;
  final String lastName;
  final AccountStatus status;
  final DateTime createdAd;

  Userprofile({required this.userId, required this.username, required this.firstName, required this.middleName, required this.lastName, required this.status, required this.createdAd});
}