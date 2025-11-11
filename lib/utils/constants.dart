import 'package:flutter/material.dart';

// 컬러 상수
class AppColors {
  // 카카오톡 노란색
  static const Color kakaoYellow = Color(0xFFFEE500);

  // 기본 색상
  static const Color primaryText = Colors.black87;
  static const Color secondaryText = Colors.grey;
  static const Color white = Colors.white;
  static const Color red = Colors.red;
  static const Color green = Colors.green;

  // 배경색
  static const Color scaffoldBackground = Colors.white;
  static final Color messageBubbleOther = Colors.grey[200]!;
  static const Color messageBubbleMe = kakaoYellow;
}

// 텍스트 스타일
class AppTextStyles {
  // AppBar 타이틀
  static const TextStyle appBarTitle = TextStyle(
    color: AppColors.primaryText,
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );

  // 일반 타이틀
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  // 서브타이틀
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
  );

  // 본문
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.primaryText,
  );

  // 작은 텍스트
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.secondaryText,
  );

  // 버튼 텍스트
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
}

// 간격 상수
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// 보더 반경
class AppBorderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;

  static BorderRadius circular(double radius) => BorderRadius.circular(radius);
  static BorderRadius circularSm = BorderRadius.circular(sm);
  static BorderRadius circularMd = BorderRadius.circular(md);
  static BorderRadius circularLg = BorderRadius.circular(lg);
  static BorderRadius circularXl = BorderRadius.circular(xl);
}

// 아이콘 크기
class AppIconSize {
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
  static const double xxl = 64.0;
}

// 에러 메시지
class AppMessages {
  static const String networkError = '네트워크 오류가 발생했습니다';
  static const String unknownError = '알 수 없는 오류가 발생했습니다';
  static const String loginSuccess = '로그인되었습니다';
  static const String logoutSuccess = '로그아웃되었습니다';
  static const String signupSuccess = '회원가입이 완료되었습니다';
}

// 앱 정보
class AppInfo {
  static const String appName = 'Simple Messenger';
  static const String version = '1.0.0';
}
