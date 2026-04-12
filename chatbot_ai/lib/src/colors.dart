import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // this basically makes it so you can't instantiate this class


  static const darkSecondaryColor = Color.fromARGB(255, 6, 47, 67);
  static const lightSecondaryColor = Color.fromARGB(255, 242, 242, 242);
  static const baabRedColor = Color.fromARGB(255, 227, 15, 15);
  static const baabRedColor2 = Color.fromRGBO(237, 66, 102, 1);
  static const baabYellowColor = Color(0xfff8d512);
  static const baabGreenColor = Color.fromRGBO(11, 136, 130, 1);
  static const baabGreyColor = Color.fromARGB(255, 156, 166, 186);

  static const primaryColor = Color(0xff0099CC);
  static const secondaryColor = Color(0xff0074A9);
  static const lightPrimaryColor = Color(0xffE6F5FA);

  static const white = Colors.white;
  static const black = Colors.black;
  static const blackLight = Color(0xff7E8085);
  static const blackDark = Color(0xff27364E);
  static const lightBlack2 = Color(0xff727272);
  static const blackOff = Color(0xff161616);
  static const purple = Color(0xff0050C9);
  static const light_purple = Color(0xffFF7300);
  static const dark_green = Color(0xff00685A);
  static const gray = Color(0xff4E4E4E);
  static const light_gray = Color(0xffF6F7FB);
  static const transparent = Colors.transparent;
  static const green =Color(0xff17C653);
  static const red = Color(0xffFDECF0);

  static const Color mainColor = Color(0xffFB4C1F);
  static const Color redColor = Color(0xffF50100);
  static const Color offWhite = Color(0xffF7F7F7);
  static const Color grayCheck = Color(0xffC9C9C9);
  static const Color foodInt = Color(0xff110E10);
  static const Color blueBackground = Color(0xff0074A9);
  static const Color linkedinButBackground = Color(0xff0074FC);
  static const Color linkedinButBorder = Color(0xff0A66C2);
  static const Color mainRed = Color(0xffFF0000);
  static const Color mainGray = Color(0xff707070);
  static const Color lightGrey = Color(0xffD9D9D9);
  static const Color chartGray = Color(0xff979797);
  static const Color mainOrange = Color(0xffFE793D);
  static const Color darkOrange = Color(0xffFC5F2C);
  static const Color mainYellow = Color(0xffF4DE6E);
  static const Color mainGreen = Color(0xffA05D2D);
  static const Color darkGreen = Color(0xff8B4513);
  static const Color secondaryGreen = Color(0xff39A95E);
  static const Color greenSub = Color(0xff50CD89);
  static const Color greenSubBack = Color(0xffE1F0ED);
  static const Color indicatorBGColor = Color(0xffE1E5EB);
  static const Color mainDarkGray = Color(0xff0A0615);
  static const Color darkGray = Color(0xff3B3B3B);
  static const Color lightBlue = Color(0xffC2D1E5);
  static const Color lightDarkBlue = Color(0xffE5F5FA);
  static const Color lightRed = Color(0xffFBC6D0);
  static const Color mainLightBlue = Color(0xffF1F4F8);
  static const Color lightYellow = Color(0xffFFF2EC);
  static const Color darkGray2 = Color(0xff292D32);
  static const Color lightBlack = Color(0xff323232);
  static const Color border = Color(0xff838FA0);
  static const Color checkEmail = Color(0xff8A94A4);
  static const Color bottomNavigation = Color(0xff292D32);
  static const Color backgroundDetails = Color(0xffF5F5F5);
  static const Color borderCard = Color(0xffc9c9d1);
  static const Color foodColor = Color(0xff292D35);
  static const Color foodFilterColor = Color(0xff1E3050);

  static const Color scaffoldBGColor = Color(0xffF1F4F8);
  static const Color appBarBGColor = Color(0xffF6F7FA);

}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}
