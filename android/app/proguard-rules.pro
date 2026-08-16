# Keep plugin entry points that are registered by Flutter or accessed by Android reflection.
-keep class io.flutter.plugins.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.syncfusion.flutter.pdfviewer.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
-dontwarn com.syncfusion.flutter.pdfviewer.**
