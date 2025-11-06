import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:packer/constants/app_colors.dart';

ThemeData lightTheme(BuildContext context) {
  // final widthExceeds = MediaQuery.of(context).size.width > 380;
  return ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primaryColor,
    brightness: Brightness.light,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    inputDecorationTheme: const InputDecorationTheme(
      fillColor: Color(0xffF3F3F3),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
    ),
    scaffoldBackgroundColor: AppColors.backgroundColor,
    // colorSchemeSeed: Colors.blue,

    textTheme: GoogleFonts.poppinsTextTheme(
      TextTheme(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 0,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 22.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xff000000),
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xff000000),
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xff000000),
          letterSpacing: 0,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xff000000),
          letterSpacing: 0,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xff7D7C7C),
          letterSpacing: 0,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xff505050),
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 10.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xff000000),
        ),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryColor,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w500,
      ),
      type: BottomNavigationBarType.fixed,
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.all(AppColors.primaryColor),
    ),
  );
}

ThemeData darkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: Colors.blue,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: AppColors.primaryColor,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
