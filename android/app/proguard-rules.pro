# ---------------------------------------------------------------------------
# Keyel R8 / ProGuard rules (release builds only).
#
# Flutter's Gradle plugin already turns on R8 (`isMinifyEnabled = true`) and
# resource shrinking for the release build type, and adds
# `proguard-android-optimize.txt`, the Flutter `flutter_proguard_rules.pro` and
# this file. The Flutter rules already keep every `FlutterPlugin`
# implementation and silence the usual embedding `-dontwarn`s, so the rules
# below only cover what R8 cannot infer on its own.
#
# Verify after changing anything here:
#   flutter build apk --release --target-platform android-arm64
#   unzip -l build/app/outputs/flutter-apk/app-release.apk | grep -i rust
# ---------------------------------------------------------------------------

# Components referenced by name from AndroidManifest.xml. AGP keeps manifest
# components automatically, but the autofill service and picker activity are
# security-critical: pin them so obfuscation can never rename the class the
# system binds to or launches.
-keep class com.freesoftware.keyel.autofill.** { *; }
-keep class com.freesoftware.keyel.MainActivity { *; }

# flutter_rust_bridge talks to Rust over dart:ffi (no JNI, no reflection), so
# its generated bindings need no keep rules. Keep the native-method surface
# defensively for any JNI-based plugin (e.g. package:jni).
-keepclasseswithmembernames class * {
    native <methods>;
}

# Honor AndroidX @Keep.
-keep @androidx.annotation.Keep class * { *; }
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}
