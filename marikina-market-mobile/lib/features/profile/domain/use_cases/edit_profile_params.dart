class EditProfileParams {
  final String firstName;
  final String? middleName;
  final String lastName;
  final DateTime dateOfBirth;
  final String email;
  final String phoneNumber;
  final String houseNumber;
  final String street;
  final String barangay;
  final String city;

  const EditProfileParams({
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.dateOfBirth,
    required this.email,
    required this.phoneNumber,
    required this.houseNumber,
    required this.street,
    required this.barangay,
    required this.city,
  });
}
