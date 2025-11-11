# FlutterFire CLI 문제 해결 가이드

## 🔍 FlutterFire CLI가 안 되는 경우

### 문제 진단 및 해결 방법

---

## 1️⃣ FlutterFire CLI 설치 확인

### 확인 방법
```bash
flutterfire --version
```

### 문제: "명령을 찾을 수 없습니다" 또는 "command not found"

**해결 방법 A: FlutterFire CLI 설치**
```bash
dart pub global activate flutterfire_cli
```

**해결 방법 B: PATH 환경 변수 추가**

Windows의 경우, Dart의 pub global 경로를 PATH에 추가해야 합니다:

1. 기본 pub cache 위치 확인:
   ```
   %USERPROFILE%\AppData\Local\Pub\Cache\bin
   또는
   C:\Users\[사용자명]\AppData\Local\Pub\Cache\bin
   ```

2. 시스템 환경 변수에 추가:
   - Windows 검색 → "환경 변수" 입력
   - "시스템 환경 변수 편집" 클릭
   - "환경 변수" 버튼 클릭
   - "사용자 변수" → "Path" 선택 → "편집"
   - "새로 만들기" → 위의 경로 추가
   - 확인 → 터미널 재시작

3. 터미널 재시작 후 다시 시도:
   ```bash
   flutterfire --version
   ```

---

## 2️⃣ Firebase 로그인 문제

### 확인 방법
```bash
firebase login:list
```

### 문제: "firebase: command not found"

**해결 방법: Firebase CLI 설치**
```bash
npm install -g firebase-tools

# 설치 확인
firebase --version

# Firebase 로그인
firebase login
```

### 문제: npm이 없음

**해결 방법: Node.js 설치**
1. [Node.js 공식 사이트](https://nodejs.org/) 다운로드
2. LTS 버전 설치
3. 터미널 재시작
4. 다시 시도:
   ```bash
   npm --version
   node --version
   ```

---

## 3️⃣ 수동 설정 방법 (FlutterFire CLI 없이)

FlutterFire CLI가 계속 안 되면 수동으로 설정하세요:

### 1단계: Firebase Console에서 앱 등록

#### Android
1. Firebase Console → 프로젝트 설정 → Android 앱 추가
2. 패키지 이름: `com.yourname.chat_messenger`
3. `google-services.json` 다운로드
4. `android/app/google-services.json`에 복사

#### iOS (선택사항)
1. Firebase Console → 프로젝트 설정 → iOS 앱 추가
2. 번들 ID: `com.yourname.chatMessenger`
3. `GoogleService-Info.plist` 다운로드
4. `ios/Runner/GoogleService-Info.plist`에 복사

### 2단계: firebase_options.dart 수동 생성

`lib/firebase_options.dart` 파일을 다음 내용으로 생성:

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Firebase Console → 프로젝트 설정 → 앱에서 가져온 정보
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.yourname.chatMessenger',
  );
}
```

### 3단계: Firebase Console에서 설정 값 가져오기

1. Firebase Console → 프로젝트 설정 → 일반 탭
2. "내 앱" 섹션에서 Android/iOS 앱 선택
3. "SDK 설정 및 구성" 확장
4. "구성" 탭에서 값 복사:
   - `apiKey`
   - `appId`
   - `projectId`
   - `messagingSenderId`
   - `storageBucket`

5. 위의 `firebase_options.dart`에 값 붙여넣기

### 4단계: android/build.gradle 수정

`android/build.gradle` 파일의 `dependencies` 섹션에 추가:

```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

### 5단계: android/app/build.gradle 수정

`android/app/build.gradle` 파일 **맨 아래**에 추가:

```gradle
apply plugin: 'com.google.gms.google-services'
```

---

## 4️⃣ 가장 쉬운 해결 방법 (추천!)

### 옵션 1: Android Studio에서 직접 연결

1. Android Studio에서 프로젝트 열기
2. Tools → Firebase
3. "Cloud Firestore" 또는 "Authentication" 선택
4. "Connect to Firebase" 클릭
5. Firebase 프로젝트 선택 또는 새로 생성
6. 자동으로 `google-services.json` 추가됨

### 옵션 2: google-services.json만 추가

FlutterFire CLI 대신 `google-services.json` 파일만 추가해도 대부분 작동합니다:

1. Firebase Console → 프로젝트 설정
2. Android 앱 선택
3. `google-services.json` 다운로드
4. `android/app/` 폴더에 복사
5. 앱 재시작

기존 `lib/firebase_options.dart` 파일은 템플릿이지만, `google-services.json`이 있으면 Firebase가 자동으로 설정을 읽어옵니다.

---

## 5️⃣ 검증 방법

설정이 제대로 되었는지 확인:

```bash
# 1. 패키지 설치
flutter pub get

# 2. 앱 실행
flutter run

# 3. 로그 확인
# 콘솔에서 Firebase 초기화 성공 메시지 확인:
# "Successfully initialized Firebase" 또는
# "[firebase_core] Firebase initialized successfully"
```

---

## 6️⃣ 여전히 안 되는 경우

### 최소 설정으로 테스트

1. **Authentication만 먼저 테스트**
   - Firebase Console → Authentication 활성화
   - 회원가입/로그인만 테스트
   - Firestore는 나중에

2. **로컬 에뮬레이터 사용**
   ```bash
   # Firebase 에뮬레이터 설치
   npm install -g firebase-tools

   # 에뮬레이터 시작
   firebase emulators:start
   ```

3. **디버그 로그 확인**
   ```bash
   flutter run --verbose
   ```
   에러 메시지를 자세히 확인하세요.

---

## 📋 체크리스트

설정이 완료되었는지 확인:

- [ ] `google-services.json` 파일이 `android/app/` 폴더에 있음
- [ ] `android/app/build.gradle`에 `google-services` 플러그인 추가됨
- [ ] Firebase Console에서 Authentication 활성화됨
- [ ] Firebase Console에서 Firestore Database 생성됨
- [ ] Firestore 보안 규칙이 테스트 모드로 설정됨
- [ ] `flutter pub get` 실행 완료
- [ ] 앱 재시작

---

## 🆘 추가 도움이 필요한 경우

1. **에러 메시지 전체 복사**
   - 콘솔의 에러 메시지 전체를 저장

2. **로그 파일 확인**
   ```bash
   flutter run --verbose 2>&1 | tee flutter_log.txt
   ```

3. **Flutter Doctor 실행**
   ```bash
   flutter doctor -v
   ```

4. **Firebase 프로젝트 설정 확인**
   - Firebase Console → 프로젝트 설정
   - 앱이 제대로 등록되었는지 확인

---

## ✅ 성공 확인

다음이 표시되면 설정 성공:

```
✓ 회원가입 버튼 클릭 → "회원가입이 완료되었습니다!"
✓ Firebase Console → Authentication → Users 탭에 사용자 표시
✓ Firebase Console → Firestore → users 컬렉션에 문서 생성
```

축하합니다! 🎉
