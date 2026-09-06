# Implementation Plan - Fix R8 Build Failure and Plugin KGP Warnings

The project is failing to build in release mode due to missing classes during R8 minification. Additionally, there are warnings about plugins using an outdated way of applying the Kotlin Gradle Plugin (KGP).

## Proposed Changes

### [Android Configuration]

#### [NEW] [proguard-rules.pro](file:///C:/Users/dharm/StudioProjects/sih/android/app/proguard-rules.pro)
- Create a new Proguard rules file to ignore warnings for missing annotations (`errorprone` and `javax.annotation`) and ensure `google.crypto.tink` (used by `flutter_secure_storage`) is handled correctly.

#### [MODIFY] [build.gradle.kts](file:///C:/Users/dharm/StudioProjects/sih/android/app/build.gradle.kts)
- Add the `proguardFiles` configuration to the `release` build type to point to `proguard-rules.pro`.

### [Dependencies]

#### [MODIFY] [pubspec.yaml](file:///C:/Users/dharm/StudioProjects/sih/pubspec.yaml)
- Upgrade dependencies to their latest stable versions to resolve KGP warnings and improve compatibility.
  - `flutter_secure_storage`: 9.2.2 -> ^11.0.0
  - `permission_handler`: 11.3.0 -> ^13.0.1
  - `speech_to_text`: ^7.4.0 -> ^7.5.0 (or latest)
  - `flutter_tts`: ^4.2.5 -> ^4.2.5 (check for latest)

## Verification Plan

### Automated Tests
- Run `flutter pub get` to ensure dependencies resolve.
- Attempt a release build (static analysis only, as I cannot run a full build here, but I can check if R8 rules are correctly referenced).
- Run `analyze_file` on `build.gradle.kts` to ensure syntax is correct.

### Manual Verification
- The user should run `flutter build apk --release` (or `assembleRelease`) to verify the build completes successfully.
