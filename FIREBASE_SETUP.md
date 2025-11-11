# Firebase 설정 가이드

## 🔥 Firebase 프로젝트 설정

### 1. Firebase Console에서 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름: `chat-messenger` (원하는 이름)
4. Google Analytics 설정 (선택사항)

---

## 📱 앱 등록

### Android 앱 추가

1. Firebase Console → 프로젝트 설정 → Android 아이콘 클릭
2. 패키지 이름: `com.yourname.chat_messenger`
3. `google-services.json` 다운로드
4. `android/app/` 폴더에 복사

### iOS 앱 추가

1. Firebase Console → 프로젝트 설정 → iOS 아이콘 클릭
2. 번들 ID: `com.yourname.chatMessenger`
3. `GoogleService-Info.plist` 다운로드
4. Xcode에서 `Runner` 프로젝트에 추가

---

## 🔧 Firebase 서비스 활성화

### 1. Authentication 설정

1. Firebase Console → Authentication
2. "시작하기" 클릭
3. **로그인 방법** 탭 → **이메일/비밀번호** 활성화
4. "사용 설정" 체크 → 저장

### 2. Cloud Firestore 설정

1. Firebase Console → Firestore Database
2. "데이터베이스 만들기" 클릭
3. **테스트 모드**로 시작 선택
4. 위치: `asia-northeast3` (서울) 선택
5. "사용 설정" 클릭

### 3. Firebase Storage 설정

1. Firebase Console → Storage
2. "시작하기" 클릭
3. **테스트 모드**로 시작 선택
4. "완료" 클릭

---

## 🛡️ Firestore 보안 규칙 배포

### 방법 1: Firebase Console에서 직접 설정

1. Firestore Database → **규칙** 탭
2. 다음 규칙 복사/붙여넣기:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 테스트용 - 모든 접근 허용
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

3. "게시" 클릭

### 방법 2: Firebase CLI로 배포

```bash
# Firebase CLI 설치 (한 번만)
npm install -g firebase-tools

# Firebase 로그인
firebase login

# 프로젝트 초기화
firebase init firestore

# Firestore 규칙 배포
firebase deploy --only firestore:rules
```

---

## 📊 Firestore 인덱스 설정

### 방법 1: 자동 생성 (권장)

1. 앱을 실행하고 채팅방 목록을 열면 콘솔에 인덱스 생성 링크가 표시됩니다
2. 링크를 클릭하여 Firebase Console로 이동
3. "인덱스 만들기" 버튼 클릭
4. 인덱스가 생성될 때까지 대기 (1-2분 소요)

### 방법 2: Firebase CLI로 배포

```bash
firebase deploy --only firestore:indexes
```

### 방법 3: Firebase Console에서 수동 생성

필요한 인덱스:

**chatRooms 컬렉션:**
- 필드 1: `participants` (배열 포함)
- 필드 2: `lastMessageTime` (내림차순)

---

## 🔐 Storage 보안 규칙 설정

1. Storage → **규칙** 탭
2. 다음 규칙 복사/붙여넣기:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 프로필 이미지
    match /profile_images/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // 채팅 이미지
    match /chat_images/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

3. "게시" 클릭

---

## 🔑 FlutterFire CLI 설정 (자동 설정)

### 1. FlutterFire CLI 설치

```bash
# Dart pub global activate
dart pub global activate flutterfire_cli
```

### 2. Firebase 프로젝트와 연결

```bash
# 프로젝트 루트에서 실행
cd C:\devpjt\mobile_app\chat_messenger

# FlutterFire 설정 (기존 firebase_options.dart를 덮어씀)
flutterfire configure
```

3. 프로젝트 선택 및 플랫폼 선택
   - Firebase 프로젝트 선택
   - Android, iOS 선택
   - 자동으로 `lib/firebase_options.dart` 생성

---

## ✅ 설정 확인

### 1. 패키지 설치

```bash
flutter pub get
```

### 2. 앱 실행

```bash
flutter run
```

### 3. 회원가입 테스트

1. 회원가입 화면에서 이메일, 비밀번호, 닉네임 입력
2. "회원가입" 버튼 클릭
3. Firestore Console → `users` 컬렉션에서 새 사용자 문서 확인

### 4. 로그인 테스트

1. 로그인 화면에서 이메일, 비밀번호 입력
2. "로그인" 버튼 클릭
3. 홈 화면 표시 확인

---

## 🐛 문제 해결

### Firestore 연결 실패 (10초 타임아웃)

**원인:** Firestore Database가 활성화되지 않았거나 보안 규칙이 설정되지 않음

**해결:**
1. Firebase Console → Firestore Database 확인
2. 데이터베이스가 생성되었는지 확인
3. 보안 규칙이 설정되었는지 확인

### "Missing Index" 오류

**원인:** Firestore 복합 인덱스가 생성되지 않음

**해결:**
1. 콘솔에 표시된 인덱스 생성 링크 클릭
2. "인덱스 만들기" 버튼 클릭
3. 1-2분 대기 후 앱 재시작

### 사용자 문서가 생성되지 않음

**원인:** Firestore 보안 규칙이 너무 제한적

**해결:**
1. Firestore 보안 규칙을 테스트 모드로 변경
2. 위의 "Firestore 보안 규칙 배포" 섹션 참고

### Authentication 오류

**원인:** Firebase Authentication이 활성화되지 않음

**해결:**
1. Firebase Console → Authentication
2. "시작하기" 클릭
3. 이메일/비밀번호 로그인 방법 활성화

---

## 📝 프로덕션 배포 전 체크리스트

- [ ] Firestore 보안 규칙을 프로덕션 모드로 변경
- [ ] Storage 보안 규칙 검토
- [ ] Firebase Billing 계정 설정 (무료 티어 제한 확인)
- [ ] Google Analytics 설정 (선택사항)
- [ ] Firebase Cloud Messaging 설정 (푸시 알림)
- [ ] 앱 서명 키 백업

---

## 📚 참고 자료

- [Firebase 공식 문서](https://firebase.google.com/docs)
- [FlutterFire 공식 문서](https://firebase.flutter.dev/)
- [Firestore 보안 규칙 가이드](https://firebase.google.com/docs/firestore/security/get-started)
