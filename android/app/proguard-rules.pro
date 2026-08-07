# Loopweek release-build rules.
#
# Flutter's Gradle plugin runs R8 (code shrinking + obfuscation) on release
# builds by default and picks this file up automatically. Without the rules
# below, release builds silently break flutter_local_notifications v17:
#
# The plugin serializes every scheduled notification to JSON (Gson) and the
# alarm receiver deserializes it when the reminder fires. R8 strips generic
# signatures and renames reflection-only fields/classes, so that round-trip
# fails at fire time -> the notification never shows, and the plugin's
# persisted "scheduled notifications" cache becomes unreadable (the classic
# "Missing type parameter" crash).
#
# The Gson rules are the canonical set recommended by the plugin README:
# https://github.com/MaikuB/flutter_local_notifications (Release builds)
# https://github.com/google/gson/blob/master/examples/android-proguard-example/proguard.cfg

## Gson ----------------------------------------------------------------
# Gson uses generic type information stored in a class file when working with
# fields. Proguard removes such information by default, so keep all of it.
-keepattributes Signature

# For using GSON @Expose annotation
-keepattributes *Annotation*

# Gson specific classes
-dontwarn sun.misc.**
#-keep class com.google.gson.stream.** { *; }

# Prevent proguard from stripping interface information from TypeAdapter,
# TypeAdapterFactory, JsonSerializer, JsonDeserializer instances (so they can
# be used in @JsonAdapter).
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Prevent R8 from leaving Data object members always null
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Retain generic signatures of TypeToken and its subclasses with R8 version
# 3.0 and higher.
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

## flutter_local_notifications ------------------------------------------
# Keep the plugin's classes (and their names!) intact: Gson round-trips the
# notification detail models, and the StyleInformation type adapter keys its
# subtypes by class simple name. The plugin ships no consumer ProGuard rules,
# so this is required for scheduled notifications to survive release builds.
-keep class com.dexterous.** { *; }

