import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/edit_profile_params.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_state.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/edit_profile_field.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/save_btn.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/back_btn.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_date_picker_dialog.dart';

class EditProfileCard extends StatefulWidget {
  final User user;
  const EditProfileCard({super.key, required this.user});

  @override
  State<EditProfileCard> createState() => _EditProfileCardState();
}

class _EditProfileCardState extends State<EditProfileCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _middleName;
  late final TextEditingController _lastName;
  late final TextEditingController _birthDate;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _house;
  late final TextEditingController _street;
  late final TextEditingController _barangay;
  late final TextEditingController _city;
  late DateTime _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _firstName = TextEditingController(text: user.firstName);
    _middleName = TextEditingController(text: user.middleName ?? '');
    _lastName = TextEditingController(text: user.lastName);
    _selectedBirthDate = DateTime(
      user.dateOfBirth.year,
      user.dateOfBirth.month,
      user.dateOfBirth.day,
    );
    _birthDate = TextEditingController(text: _dateText(_selectedBirthDate));
    _email = TextEditingController(text: user.email);
    _phone = TextEditingController(text: user.mobileNumber);
    _house = TextEditingController(text: user.houseNumber);
    _street = TextEditingController(text: user.street);
    _barangay = TextEditingController(text: user.barangay);
    _city = TextEditingController(text: user.city);
  }

  String _dateText(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickBirthDate() async {
    final today = _today();
    final firstDate = DateTime(1);
    final initialDate = _selectedBirthDate.isAfter(today)
        ? today
        : _selectedBirthDate.isBefore(firstDate)
        ? firstDate
        : _selectedBirthDate;
    FocusScope.of(context).unfocus();
    final date = await showDialog<DateTime>(
      context: context,
      builder: (_) => AppDatePickerDialog(
        title: 'Date of birth',
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: today,
      ),
    );
    if (!mounted || date == null) return;
    setState(() {
      _selectedBirthDate = date;
      _birthDate.text = _dateText(date);
    });
  }

  void _save() {
    if (context.read<ProfileBloc>().state is EditProfileLoading) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final middleName = _middleName.text.trim();
    context.read<ProfileBloc>().add(
      EditProfileSubmitted(
        EditProfileParams(
          firstName: _firstName.text.trim(),
          middleName: middleName.isEmpty ? null : middleName,
          lastName: _lastName.text.trim(),
          dateOfBirth: _selectedBirthDate,
          email: _email.text.trim(),
          phoneNumber: _phone.text.trim(),
          houseNumber: _house.text.trim(),
          street: _street.text.trim(),
          barangay: _barangay.text.trim(),
          city: _city.text.trim(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _middleName,
      _lastName,
      _birthDate,
      _email,
      _phone,
      _house,
      _street,
      _barangay,
      _city,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ProfileBloc, ProfileState>(
    builder: (context, state) {
      final loading = state is EditProfileLoading;
      return Container(
        padding: AppTheme.profileCardPadding,
        decoration: AppTheme.profileCardDecoration(context),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EditProfileField(
                label: 'FIRST NAME',
                controller: _firstName,
                maxLength: 100,
                enabled: !loading,
              ),
              EditProfileField(
                label: 'MIDDLE NAME (OPTIONAL)',
                controller: _middleName,
                maxLength: 100,
                enabled: !loading,
                requiredField: false,
              ),
              EditProfileField(
                label: 'LAST NAME',
                controller: _lastName,
                maxLength: 100,
                enabled: !loading,
              ),
              EditProfileField(
                label: 'DATE OF BIRTH',
                controller: _birthDate,
                enabled: !loading,
                readOnly: true,
                hintText: 'YYYY-MM-DD',
                onTap: loading ? null : _pickBirthDate,
                suffixIcon: const Icon(Icons.calendar_today),
                validator: (_) => _selectedBirthDate.isAfter(_today())
                    ? 'Birth date cannot be in the future.'
                    : null,
              ),
              EditProfileField(
                label: 'EMAIL',
                controller: _email,
                maxLength: 255,
                enabled: !loading,
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                    ).hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Enter a valid email address.',
              ),
              EditProfileField(
                label: 'PHONE NUMBER',
                controller: _phone,
                enabled: !loading,
                keyboardType: TextInputType.phone,
                hintText: '09171234567',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (value) =>
                    RegExp(r'^09[0-9]{9}$').hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Use 11 digits starting with 09.',
              ),
              EditProfileField(
                label: 'HOUSE NUMBER',
                controller: _house,
                maxLength: 50,
                enabled: !loading,
              ),
              EditProfileField(
                label: 'STREET',
                controller: _street,
                maxLength: 100,
                enabled: !loading,
              ),
              EditProfileField(
                label: 'BARANGAY',
                controller: _barangay,
                maxLength: 100,
                enabled: !loading,
              ),
              EditProfileField(
                label: 'CITY',
                controller: _city,
                maxLength: 100,
                enabled: !loading,
              ),
              if (state is EditProfileError)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.profileGap),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              SaveBtn(
                key: const ValueKey('save_profile'),
                onPressed: _save,
                isLoading: loading,
              ),
              const SizedBox(height: AppTheme.profileSmallGap),
              BackBtn(enabled: !loading),
            ],
          ),
        ),
      );
    },
  );
}
