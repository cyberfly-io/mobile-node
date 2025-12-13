# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Flutter Rust Bridge - keep JNI
-keep class io.cyberfly.cyberfly_mobile_node.** { *; }
-keep class com.example.** { *; }

# Rust library - keep all native bindings
-keep class rust_lib_cyberfly_mobile_node.** { *; }

# Keep R8/ProGuard from stripping JNI methods
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# flutter_background_service
-keep class id.flutter.flutter_background_service.** { *; }

# Kadena SDK
-keep class com.pactlang.** { *; }
-keep class kadena.** { *; }

# Keep serialization classes (JSON)
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep exceptions
-keepattributes Exceptions

# Prevent stripping of logging
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# OkHttp (used by http package)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Prevent R8 from warning about missing classes
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Google Play Core - not used but referenced by Flutter
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
