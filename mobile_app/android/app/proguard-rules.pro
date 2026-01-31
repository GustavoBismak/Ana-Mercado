# Flutter specific ProGuard rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep R8 compatibility
-dontwarn com.google.android.material.**
-keep class com.google.android.material.** { *; }

# Keep annotations
-keepattributes *Annotation*

# Play Core (deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
