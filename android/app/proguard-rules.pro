# Flutter embedding. Names stay stable; app and plugin code is still obfuscated by R8.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Plugins depend on the embedding, which R8 treats as the program jar.
-dontwarn io.flutter.plugin.**
-dontwarn android.**

# Keep FlutterPlugin implementations, but allow R8 to obfuscate and shrink them.
-if class * implements io.flutter.embedding.engine.plugins.FlutterPlugin
-keep,allowshrinking,allowobfuscation class <1>

# Flutter deferred components reference Play Core classes that are not packaged.
-dontwarn com.google.android.play.core.**

# webview_flutter
-keep class io.flutter.plugins.webviewflutter.** { *; }
-dontwarn android.webkit.**

# OneSignal
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# Sentry
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**
