# Keep all application classes
-keep class com.abynk.smart_assistant.** { *; }

# Keep alarm plugin classes
-keep class com.gdelataillade.alarm.** { *; }

# Keep connectivity plugin classes
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Keep notification plugin classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep home widget plugin classes
-keep class es.antonborri.home_widget.** { *; }

# Keep permission handler classes
-keep class com.baseflow.permissionhandler.** { *; }

# Keep shared preferences classes
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep path provider classes
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep PDF library classes
-keep class com.tom_roush.pdfbox.** { *; }

# PDF library optional dependencies - suppress warnings
-dontwarn com.gemalto.jp2.**
-dontwarn org.bouncycastle.**
-dontwarn org.apache.commons.logging.**
