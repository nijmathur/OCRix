# Keep ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.** { *; }
-dontwarn com.google.mlkit.**

# Keep Chinese text recognition
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**

# Keep Devanagari text recognition
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-dontwarn com.google.mlkit.vision.text.devanagari.**

# Keep Japanese text recognition
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-dontwarn com.google.mlkit.vision.text.japanese.**

# Keep Korean text recognition
-keep class com.google.mlkit.vision.text.korean.** { *; }
-dontwarn com.google.mlkit.vision.text.korean.**
