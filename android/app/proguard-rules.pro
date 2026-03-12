# Flutter Native Library Protection Rules
# Prevents ProGuard from stripping critical native libraries

# Keep all native libraries
-keep class io.flutter.** { *; }
-keep class com.getkeepsafe.relinker.** { *; }

# Prevent stripping of Flutter engine
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep native method signatures
-keepclasseswithmembernames class * {
    native <methods>;
}

# Prevent obfuscation of Flutter-related classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Firebase classes (used in the app)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep billing client classes
-keep class com.android.billingclient.** { *; }

# Don't warn about missing classes that are platform-specific
-dontwarn io.flutter.**
-dontwarn com.getkeepsafe.relinker.**

# Keep application class
-keep public class * extends android.app.Application
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service

# Preserve line numbers for debugging crashes
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile