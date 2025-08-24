# claude_project / othello_game
目的: 学習用のオセロ実装。人間 vs 人間 → 簡易AI まで。

## 使い方
### C++/CMake
mkdir -p build && cd build && cmake .. && cmake --build . && ./othello

### Flutter(ある場合)
flutter run -d chrome
# 学習用ビルド保存:
flutter build web --release && mkdir -p ../artifacts/web && cp -r build/web/* ../artifacts/web/
flutter build apk --release && cp build/app/outputs/flutter-apk/app-release.apk ../artifacts/app.apk

## 構成
- othello_game/ ... コア実装（C++ ほか）
- artifacts/ ... ビルド成果物（学習の保存用）
