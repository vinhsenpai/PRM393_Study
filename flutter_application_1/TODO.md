# TODO

## Task: Change Android applicationId/package to `com.example.Prm393_Group5` for building APK

- [ ] Review relevant Android config files (android/app/build.gradle.kts, AndroidManifest.xml, MainActivity.kt)
- [ ] Edit `android/app/build.gradle.kts`: set `namespace` and `applicationId`
- [ ] Edit `android/app/src/main/AndroidManifest.xml`: update `android:name` for MainActivity
- [ ] Edit `android/app/src/main/kotlin/.../MainActivity.kt`: update `package` declaration
- [ ] Run `flutter clean` and `flutter build apk --release` to verify build

