# Thyme Frontend

교대 근무 매장 근무표 자동 생성 앱 Thyme의 Flutter 앱입니다.

- 화면 설계·플로우맵: [store-scheduler-design](https://github.com/kw-store-scheduler/store-scheduler-design)
- 서버: [store-scheduler-backend](https://github.com/kw-store-scheduler/store-scheduler-backend)
- 배포 주소: https://thyme-6730c.web.app

## 실행

```bash
flutter pub get
flutter run                                   # 서버 주소를 안 주면 로컬(localhost:8080, 안드로이드 에뮬레이터는 10.0.2.2:8080)
flutter run --dart-define=API_BASE_URL=https://store-scheduler-backend-cqpv.onrender.com
```

- 로그인은 아이디·비밀번호입니다 (백엔드에 소셜·휴대폰 로그인이 아직 없음). 로그인 화면에서 회원가입도 됩니다.
- 로그인은 브라우저 저장소(shared_preferences)에 남아서 새로고침해도 유지되고, 토큰이 만료되면 로그인 화면으로 돌아갑니다.

## 웹 빌드 · 배포 (Firebase Hosting)

**서버 주소를 꼭 넣어야 합니다.** 빠뜨리면 localhost로 붙어서 배포한 화면에서 서버 연결이 안 됩니다.

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://store-scheduler-backend-cqpv.onrender.com
firebase deploy --only hosting
```

- 배포 설정은 `firebase.json`의 `hosting`(build/web, 모든 경로를 index.html로)과 `.firebaserc`(프로젝트 thyme-6730c)에 있습니다.
- 루트 경로에 올리므로 `--base-href`는 필요 없습니다. GitHub Pages처럼 하위 경로(`/store-scheduler-frontend/`)에 올릴 때만
  `--base-href /store-scheduler-frontend/`를 붙입니다.
- 백엔드의 `CORS_ALLOWED_ORIGINS`에 배포 주소(`https://thyme-6730c.web.app`, `https://thyme-6730c.firebaseapp.com`)가 있어야 화면에서 API가 불립니다.

## 테스트

```bash
flutter analyze
flutter test                                  # 화면 스모크 · 플로우맵 흐름 · 희망 제출 (가짜 서버)
```

실제 백엔드에 화면을 붙여 보는 E2E (`test/live_api_test.dart`)는 서버 주소를 줄 때만 돕니다.
Docker 없이 백엔드를 띄우려면 백엔드 레포의 `Store_Scheduler_Backend`에서 `./gradlew bootTestRun`(H2 메모리 DB)을 쓰면 됩니다.

```bash
THYME_LIVE_API=http://localhost:8080 flutter test test/live_api_test.dart
```

## 코드 구조

- `lib/screens/{common,worker,owner}/<화면ID>_<이름>_page.dart` — 파일 이름 앞의 ID는 디자인 플로우맵의 화면 ID (예: `w02_date_shift_page.dart`)
- `lib/core/` — `api_service.dart`(서버 연결), `session.dart`(로그인·현재 매장), `*_api.dart`(기능별 API)
- `lib/models/` — 백엔드 응답과 같은 필드의 모델, `preference_demo.dart`(시연 데이터)
- `lib/theme/`, `lib/core/theme.dart` — 디자인 가이드 색·서체 토큰
- `lib/widgets/` — 단계 상단 바, 점주 헤더·하단 탭, 잎 모티프
