# Keep JNI / native method bindings so the native security bindings are not renamed or stripped
-keepclasseswithmembernames class * {
    native <methods>;
}

# Flutter embedding
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Do not warn about the native security library loader
-dontwarn app.kumaanime.**

-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }