# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# PDFBox / ReadPdfText Rules
-dontwarn com.gemalto.jp2.**
-dontwarn com.tom_roush.pdfbox.**
-dontwarn org.bouncycastle.**
-keep class com.tom_roush.pdfbox.** { *; }

# Generic Ignore warnings (Use with caution, but PDF libs often need it)
-ignorewarnings
