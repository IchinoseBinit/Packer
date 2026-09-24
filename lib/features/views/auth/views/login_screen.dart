import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/widgets/update_url_widget.dart';
import 'package:provider/provider.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/controllers/services/validation_mixin.dart';
import 'package:packer/features/views/auth/provider/auth_provider.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/shift_clock/utils/sign_in_refusal.dart';
import 'package:packer/features/views/shift_clock/widgets/shift_refusal_card.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/features/views/widgets/general_text_field.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/features/views/widgets/password_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();

  final passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  void handleLogin() async {
    if (formKey.currentState!.validate()) {
      final authProvider = AuthController();
      String username = usernameController.text.trim();
      String password = passwordController.text.trim();

      // A new attempt, maybe by someone else on this phone: the last refusal
      // was about whoever tried before. A refusal of this one sets it again.
      signInRefusal.value = null;
      showLoading(context);

      authProvider
          .validateLogin(context, username, password)
          .then((value) async {
        if (value is bool) {
          usernameController.clear();
          passwordController.clear();
          signInRefusal.value = null;
          final home = Provider.of<HomeProvider>(context, listen: false);
          // The user is read from the token once and kept. A 401 or a 403 -
          // the clock checking the last person out - lands here with no
          // logout to drop it, and the next person on this phone would work
          // under the last one's name, role and store.
          home.resetUser();
          home.fetchpackerSummary().then((v) {
            removeLoading(context);
            if (DioClient.token.isEmpty) return;

            navigate(context, route: NavigationConstants.dashboardRoute);
          });
        } else {
          removeLoading(context);
          // Refused outside their shift: ShiftRefusalCard already says so,
          // and keeps saying it; a toast would only repeat it.
          if (signInRefusal.value == null) showToast(value.toString());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 60.h),
                Text(
                  "Login",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                ),
                SizedBox(height: 100.h),
                Padding(
                  padding: AppConstants.padding,
                  child: Column(
                    children: [
                      Text(
                        "Welcome back! Glad to\nsee you, Again!",
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      ShiftRefusalCard(margin: EdgeInsets.only(top: 24.h)),
                      SizedBox(height: 30.h),
                      GeneralTextField(
                        hintText: "Enter your username",
                        textInputType: TextInputType.text,
                        removePrefixIconDivider: true,
                        controller: usernameController,
                        validate: (v) =>
                            ValidationMixin().validate(v, title: "Username"),
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: 20.h),
                      PasswordTextField(
                        controller: passwordController,
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Forgot password?",
                            style: TextStyle(color: AppColors.primaryColor),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      GeneralElevatedButton(
                        title: "Login",
                        isDisabled: false,
                        onPressed: () {
                          handleLogin();
                        },
                      )
                    ],
                  ),
                ),
                UpdateUrlWidget()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
