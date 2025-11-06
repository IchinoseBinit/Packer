import 'package:flutter/material.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/services/validation_mixin.dart';
import 'package:packer/features/views/widgets/general_text_field.dart';

class PasswordTextField extends StatefulWidget {
  const PasswordTextField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  var passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return GeneralTextField(
      textInputType: TextInputType.text,
      obscureText: !passwordVisible,
      validate: (v) => ValidationMixin().validate(v, title: "Password"),
      controller: widget.controller,
      suffixIcon: Icons.visibility_outlined,
      onClickPsToggle: () => setState(() => passwordVisible = !passwordVisible),
      suffixIconColor: passwordVisible ? AppColors.primaryColor : null,
      hintText: "Enter your password",
      textInputAction: TextInputAction.done,
    );
  }
}
