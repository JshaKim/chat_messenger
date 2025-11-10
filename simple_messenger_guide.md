# 심플 메신저 앱 - 완전 개발 가이드

> Flutter + Firebase 기반 크로스플랫폼 메신저 앱  
> 목표: 최소 2주 내 MVP 완성 및 배포

---

## 📋 목차
1. [프로젝트 개요](#프로젝트-개요)
2. [기술 스택](#기술-스택)
3. [프로젝트 구조](#프로젝트-구조)
4. [Firebase 설정](#firebase-설정)
5. [핵심 기능 명세](#핵심-기능-명세)
6. [단계별 구현 가이드](#단계별-구현-가이드)
7. [Claude Code 프롬프트](#claude-code-프롬프트)
8. [배포 가이드](#배포-가이드)

---

## 프로젝트 개요

### 핵심 컨셉
- 카카오톡 초기 버전처럼 **심플하고 직관적인 UI**
- 메신저로서의 **핵심 기능만** 구현
- 불필요한 기능 제거 (쇼핑, 게임, 이모티콘 스토어 등)

### MVP 필수 기능
✅ 이메일 로그인/회원가입  
✅ 사용자 목록 (친구 목록)  
✅ 1:1 채팅방  
✅ 실시간 메시지 전송/수신  
✅ 읽음/안읽음 표시  
✅ 프로필 사진  
✅ 이미지 전송  

### 제외 기능
❌ 그룹채팅 (v2에서)  
❌ 음성/영상 통화  
❌ 이모티콘 스토어  
❌ 결제 기능  
❌ 오픈채팅  
❌ 게임/미니앱  

---

## 기술 스택

### Frontend
- **Flutter 3.x** (Dart)
- **상태관리**: Provider 또는 Riverpod
- **라우팅**: go_router

### Backend
- **Firebase Authentication** (이메일/비밀번호)
- **Cloud Firestore** (실시간 데이터베이스)
- **Firebase Storage** (이미지 저장)
- **Firebase Cloud Messaging** (푸시 알림)

### 주요 패키지
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0
  firebase_messaging: ^14.7.10
  
  # 상태관리
  provider: ^6.1.1
  
  # UI/UX
  cached_network_image: ^3.3.1
  image_picker: ^1.0.7
  intl: ^0.19.0
  
  # 라우팅
  go_router: ^13.0.0
  
  # 유틸리티
  uuid: ^4.3.3
```

---

## 프로젝트 구조

```
simple_messenger/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   │
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── message_model.dart
│   │   └── chat_room_model.dart
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   └── friends_list_screen.dart
│   │   ├── chat/
│   │   │   ├── chat_list_screen.dart
│   │   │   └── chat_room_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart
│   │
│   ├── widgets/
│   │   ├── message_bubble.dart
│   │   ├── user_avatar.dart
│   │   └── chat_input_field.dart
│   │
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── chat_service.dart
│   │   ├── user_service.dart
│   │   └── storage_service.dart
│   │
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── chat_provider.dart
│   │   └── user_provider.dart
│   │
│   └── utils/
│       ├── constants.dart
│       └── helpers.dart
│
├── android/
├── ios/
├── pubspec.yaml
└── README.md
```

---

## Firebase 설정

### 1. Firebase 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름: `simple-messenger` (원하는 이름)
4. Google Analytics 선택 (선택사항)

### 2. Firebase 앱 등록

#### Android 앱 추가
1. Firebase Console → 프로젝트 설정 → Android 아이콘 클릭
2. 패키지 이름: `com.yourname.simple_messenger`
3. `google-services.json` 다운로드
4. `android/app/` 폴더에 복사

#### iOS 앱 추가
1. Firebase Console → 프로젝트 설정 → iOS 아이콘 클릭
2. 번들 ID: `com.yourname.simpleMessenger`
3. `GoogleService-Info.plist` 다운로드
4. Xcode에서 `Runner` 프로젝트에 추가

### 3. Firebase 서비스 활성화

#### Authentication
1. Firebase Console → Authentication
2. "시작하기" 클릭
3. 로그인 방법 → 이메일/비밀번호 활성화

#### Firestore Database
1. Firebase Console → Firestore Database
2. "데이터베이스 만들기"
3. **테스트 모드**로 시작 (나중에 보안 규칙 설정)
4. 위치: `asia-northeast3` (서울)

#### Storage
1. Firebase Console → Storage
2. "시작하기"
3. 테스트 모드로 시작

### 4. Firestore 보안 규칙 (초기 개발용)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자 문서
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 채팅방 문서
    match /chatRooms/{chatRoomId} {
      allow read, write: if request.auth != null;
    }
    
    // 메시지 문서
    match /chatRooms/{chatRoomId}/messages/{messageId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 5. Storage 보안 규칙

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_images/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /chat_images/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 6. FlutterFire CLI 설정

터미널에서 실행:
```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트와 연결
flutterfire configure
```

---

## 핵심 기능 명세

### 1. 인증 (Authentication)

#### 회원가입
- 입력: 이메일, 비밀번호, 닉네임
- 유효성 검사:
  - 이메일 형식 검증
  - 비밀번호 최소 6자
  - 닉네임 2-20자
- Firestore에 사용자 정보 저장

#### 로그인
- 이메일/비밀번호로 로그인
- 로그인 상태 유지
- 자동 로그인

### 2. 사용자 관리

#### 사용자 모델
```dart
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isOnline;
}
```

#### 프로필 기능
- 프로필 사진 업로드/변경
- 닉네임 변경
- 마지막 접속 시간 표시

### 3. 친구 목록

#### 기능
- 모든 사용자 목록 표시 (초기 버전)
- 사용자 검색 (이메일/닉네임)
- 온라인/오프라인 상태 표시
- 사용자 클릭 → 채팅방 이동

### 4. 채팅

#### 채팅방 모델
```dart
class ChatRoomModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount;
}
```

#### 메시지 모델
```dart
class MessageModel {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;
}
```

#### 채팅 기능
- 실시간 메시지 전송/수신
- 텍스트 메시지
- 이미지 전송
- 타임스탬프 표시
- 읽음/안읽음 표시
- 안읽은 메시지 카운트

### 5. UI/UX

#### 화면 구성
1. **로그인/회원가입 화면**
2. **홈 화면** (탭 네비게이션)
   - 친구 목록 탭
   - 채팅 목록 탭
   - 프로필 탭
3. **채팅방 화면**

#### 디자인 컨셉
- 카카오톡 초기 버전 스타일
- 노란색 (#FEE500) 메인 컬러
- 심플하고 직관적인 UI
- 말풍선 스타일 메시지

---

## 단계별 구현 가이드

### Phase 1: 프로젝트 셋업 (1일)

1. Flutter 프로젝트 생성
2. Firebase 설정
3. 필요한 패키지 설치
4. 프로젝트 폴더 구조 생성

### Phase 2: 인증 구현 (2-3일)

1. AuthService 구현
2. 로그인/회원가입 UI
3. AuthProvider 상태관리
4. 자동 로그인 처리

### Phase 3: 사용자 관리 (2일)

1. UserService 구현
2. Firestore에 사용자 정보 저장
3. 프로필 화면 구현
4. 프로필 사진 업로드

### Phase 4: 친구 목록 (2일)

1. 사용자 목록 조회
2. 친구 목록 UI
3. 온라인 상태 표시
4. 검색 기능

### Phase 5: 채팅 구현 (4-5일)

1. ChatService 구현
2. 채팅방 생성 로직
3. 채팅방 목록 UI
4. 채팅방 화면 구현
5. 실시간 메시지 송수신
6. 이미지 전송 기능
7. 읽음 표시

### Phase 6: 최적화 및 테스트 (2-3일)

1. 성능 최적화
2. 버그 수정
3. 실제 기기 테스트
4. UI/UX 개선

---

## Claude Code 프롬프트

Claude Code에서 다음 프롬프트를 순서대로 사용하세요.

### 1. 프로젝트 초기 설정

```
Flutter 프로젝트를 생성하고 Firebase를 설정해줘.

프로젝트 이름: simple_messenger
패키지 이름: com.yourname.simple_messenger

다음을 수행해줘:
1. flutter create simple_messenger 실행
2. pubspec.yaml에 필요한 패키지 추가
3. 프로젝트 폴더 구조 생성 (models, screens, services, providers, widgets, utils)
4. firebase_options.dart 템플릿 생성

필요한 패키지:
- firebase_core, firebase_auth, cloud_firestore, firebase_storage, firebase_messaging
- provider
- cached_network_image, image_picker, intl
- go_router
- uuid
```

### 2. 데이터 모델 생성

```
다음 데이터 모델을 생성해줘:

1. lib/models/user_model.dart
- uid, email, displayName, photoURL, createdAt, lastSeen, isOnline 필드
- fromJson, toJson 메서드
- copyWith 메서드

2. lib/models/chat_room_model.dart
- id, participants, lastMessage, lastMessageTime, unreadCount 필드
- fromJson, toJson 메서드

3. lib/models/message_model.dart
- id, chatRoomId, senderId, senderName, text, imageUrl, timestamp, isRead 필드
- fromJson, toJson 메서드
```

### 3. Firebase 서비스 구현

```
Firebase 서비스 클래스들을 구현해줘:

1. lib/services/auth_service.dart
- 이메일/비밀번호 회원가입
- 이메일/비밀번호 로그인
- 로그아웃
- 현재 사용자 정보 가져오기
- 인증 상태 스트림

2. lib/services/user_service.dart
- Firestore에 사용자 정보 저장
- 사용자 정보 조회
- 사용자 정보 업데이트
- 모든 사용자 목록 조회
- 온라인 상태 업데이트

3. lib/services/chat_service.dart
- 채팅방 생성 또는 가져오기
- 메시지 전송
- 메시지 스트림 가져오기
- 채팅방 목록 조회
- 읽음 처리

4. lib/services/storage_service.dart
- 프로필 사진 업로드
- 채팅 이미지 업로드
```

### 4. Provider 상태관리

```
Provider를 사용한 상태관리를 구현해줘:

1. lib/providers/auth_provider.dart
- AuthService 래핑
- 로그인/회원가입/로그아웃 상태 관리
- 로딩 상태 관리

2. lib/providers/user_provider.dart
- 현재 사용자 정보
- 사용자 목록
- 프로필 업데이트

3. lib/providers/chat_provider.dart
- 채팅방 목록
- 현재 채팅방
- 메시지 목록
```

### 5. 인증 화면 구현

```
인증 관련 화면을 구현해줘:

1. lib/screens/auth/login_screen.dart
- 이메일, 비밀번호 입력
- 로그인 버튼
- 회원가입 화면으로 이동
- 카카오톡 스타일의 노란색 테마

2. lib/screens/auth/signup_screen.dart
- 이메일, 비밀번호, 닉네임 입력
- 유효성 검사
- 회원가입 버튼
```

### 6. 홈 화면 및 친구 목록

```
홈 화면과 친구 목록을 구현해줘:

1. lib/screens/home/home_screen.dart
- BottomNavigationBar로 탭 구성
- 친구 목록, 채팅 목록, 프로필 탭

2. lib/screens/home/friends_list_screen.dart
- 모든 사용자 목록 표시
- ListView.builder 사용
- 온라인/오프라인 상태 표시
- 사용자 클릭 시 채팅방으로 이동
- 검색 기능

3. lib/widgets/user_avatar.dart
- 프로필 사진 표시 위젯
- 온라인 상태 표시 (초록색 점)
- cached_network_image 사용
```

### 7. 채팅 목록 화면

```
채팅 목록 화면을 구현해줘:

1. lib/screens/chat/chat_list_screen.dart
- 채팅방 목록 표시 (StreamBuilder)
- 마지막 메시지 미리보기
- 안읽은 메시지 개수 표시
- 시간 표시
- 채팅방 클릭 시 채팅방 화면으로 이동
```

### 8. 채팅방 화면 (핵심)

```
채팅방 화면을 구현해줘:

1. lib/screens/chat/chat_room_screen.dart
- AppBar에 상대방 정보 표시
- 메시지 목록 (StreamBuilder + ListView)
- 메시지 입력 필드
- 이미지 전송 버튼
- 자동 스크롤 (최신 메시지로)
- 읽음 표시

2. lib/widgets/message_bubble.dart
- 내 메시지 / 상대 메시지 구분
- 카카오톡 스타일 말풍선
- 타임스탬프 표시
- 이미지 메시지 지원
- 읽음 표시

3. lib/widgets/chat_input_field.dart
- TextField
- 전송 버튼
- 이미지 선택 버튼
```

### 9. 프로필 화면

```
프로필 화면을 구현해줘:

1. lib/screens/profile/profile_screen.dart
- 프로필 사진 표시 및 변경
- 닉네임 표시 및 변경
- 이메일 표시
- 로그아웃 버튼
```

### 10. 메인 및 라우팅

```
메인 파일과 라우팅을 구현해줘:

1. lib/main.dart
- Firebase 초기화
- MultiProvider 설정
- MaterialApp 설정
- 카카오톡 스타일 테마 (노란색)
- 초기 라우팅 (로그인 상태 확인)

2. lib/utils/constants.dart
- 컬러 상수 (카카오톡 노란색: #FEE500)
- 텍스트 스타일
- 기타 상수

Go Router로 라우팅 설정:
- /login → LoginScreen
- /signup → SignupScreen
- /home → HomeScreen
- /chat/:chatRoomId → ChatRoomScreen
```

### 11. 최종 통합 및 테스트

```
프로젝트를 빌드하고 테스트해줘:

1. 필요한 권한 설정 확인
   - android/app/src/main/AndroidManifest.xml (인터넷, 카메라, 저장소)
   - ios/Runner/Info.plist (사진 라이브러리, 카메라)

2. flutter pub get 실행

3. 빌드 확인
   - flutter build apk (Android)
   - flutter build ios (iOS)

4. 발견된 에러 수정
```

---

## 주요 코드 샘플

### main.dart

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Simple Messenger',
        theme: ThemeData(
          primaryColor: const Color(0xFFFEE500), // 카카오톡 노란색
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFEE500),
            foregroundColor: Colors.black87,
            elevation: 0,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return StreamBuilder(
      stream: authProvider.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}
```

### user_model.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isOnline;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.lastSeen,
    this.isOnline = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoURL: json['photoURL'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastSeen: (json['lastSeen'] as Timestamp).toDate(),
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isOnline': isOnline,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
```

### auth_service.dart

```dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 사용자
  User? get currentUser => _auth.currentUser;

  // 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 회원가입
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 로그인
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 에러 처리
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return '사용자를 찾을 수 없습니다.';
        case 'wrong-password':
          return '비밀번호가 올바르지 않습니다.';
        case 'email-already-in-use':
          return '이미 사용 중인 이메일입니다.';
        case 'weak-password':
          return '비밀번호는 6자 이상이어야 합니다.';
        case 'invalid-email':
          return '유효하지 않은 이메일 형식입니다.';
        default:
          return '인증 오류가 발생했습니다: ${e.message}';
      }
    }
    return '알 수 없는 오류가 발생했습니다.';
  }
}
```

### message_bubble.dart (카카오톡 스타일)

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe) ...[
            // 읽음 표시
            if (!message.isRead)
              const Padding(
                padding: EdgeInsets.only(right: 4.0),
                child: Text(
                  '1',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFFEE500),
                  ),
                ),
              ),
            // 시간
            Text(
              _formatTime(message.timestamp),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(width: 4),
          ],
          // 메시지 내용
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFFEE500) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: message.imageUrl != null
                  ? _buildImageMessage()
                  : _buildTextMessage(),
            ),
          ),
          if (!isMe) ...[
            const SizedBox(width: 4),
            // 시간
            Text(
              _formatTime(message.timestamp),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextMessage() {
    return Text(
      message.text,
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildImageMessage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: message.imageUrl!,
        width: 200,
        fit: BoxFit.cover,
        placeholder: (context, url) => const SizedBox(
          width: 200,
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.day == now.day) {
      return DateFormat('HH:mm').format(time);
    } else {
      return DateFormat('MM/dd HH:mm').format(time);
    }
  }
}
```

---

## 배포 가이드

### Android 배포

1. **앱 서명 설정**
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. **android/key.properties 생성**
```
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<keystore-path>
```

3. **android/app/build.gradle 수정**
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

4. **빌드**
```bash
flutter build appbundle
```

5. **Google Play Console 업로드**

### iOS 배포

1. **Apple Developer 계정 필요**
2. **Xcode에서 프로비저닝 프로필 설정**
3. **빌드**
```bash
flutter build ios
```
4. **Xcode에서 Archive → App Store Connect 업로드**

---

## 문제 해결

### Firebase 연결 문제
- `flutterfire configure` 재실행
- `google-services.json` / `GoogleService-Info.plist` 위치 확인

### 빌드 에러
- `flutter clean` → `flutter pub get`
- Android Studio / Xcode 최신 버전 확인

### 실시간 업데이트 안됨
- Firestore 보안 규칙 확인
- 인터넷 권한 확인

---

## 다음 단계 (v2 기능)

- [ ] 그룹 채팅
- [ ] 파일 전송 (문서, 영상)
- [ ] 음성 메시지
- [ ] 채팅방 검색
- [ ] 메시지 삭제
- [ ] 프로필 상태 메시지
- [ ] 친구 추가/삭제
- [ ] 차단 기능
- [ ] 다크 모드

---

## 예상 개발 기간

- **최소 MVP**: 1-2주
- **기능 완성**: 3-4주
- **테스트 및 배포**: 1주

**총 예상 기간**: 약 한 달

---

## 참고 자료

- [Flutter 공식 문서](https://flutter.dev/docs)
- [Firebase Flutter 문서](https://firebase.google.com/docs/flutter/setup)
- [Flutter Provider](https://pub.dev/packages/provider)
- [FlutterFire](https://firebase.flutter.dev/)

---

이 가이드를 Claude Code에 붙여넣고 순서대로 진행하시면 됩니다!
