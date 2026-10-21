import 'package:flutter/material.dart';

class ViolatorInfoFields extends StatelessWidget {
  final TextEditingController stallNumberController;
  final TextEditingController tradeNameController;
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;

  const ViolatorInfoFields({
    super.key, 
    required this.stallNumberController, 
    required this.tradeNameController, 
    required this.lastNameController, 
    required this.firstNameController, 
    required this.middleNameController
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'STALL/UNIT NO.'
      ),
      const SizedBox(height: 5,),
      TextFormField(
        controller: stallNumberController,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onTapOutside: (event) => FocusScope.of(context).unfocus(),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Stall or unit number is required.';
          }
          return null;
        },
        
      ),

      const SizedBox(height: 10,),

      const Text(
        'TRADE NAME'
      ),
      const SizedBox(height: 5,),
      TextFormField(
        controller: tradeNameController,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onTapOutside: (event) => FocusScope.of(context).unfocus(),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Trade or business name is required.';
          }
          return null;
        },
        
      ),

      const SizedBox(height: 10,),

      const Text(
        'LAST NAME'
      ),
      const SizedBox(height: 5,),
      TextFormField(
        controller: lastNameController,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onTapOutside: (event) => FocusScope.of(context).unfocus(),
        validator:(value) {
          if (value == null || value.trim().isEmpty) {
            return 'Last name is required.';
          }
          return null;
        },
        
      ),

      const SizedBox(height: 10,),

      const Text(
        'FIRST NAME'
      ),
      const SizedBox(height: 5,),
      TextFormField(
        controller: firstNameController,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onTapOutside: (event) => FocusScope.of(context).unfocus(),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'First name is required.';
          }
          return null;
        },
        
      ),

      const SizedBox(height: 10,),

      const Text(
        'MIDDLE NAME'
      ),
      const SizedBox(height: 5,),
      TextField(
        controller: middleNameController,
        onTapOutside: (event) => FocusScope.of(context).unfocus(),
      ),

      const SizedBox(height: 10,),
    ],
  );
}