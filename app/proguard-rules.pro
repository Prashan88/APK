# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to those in
# $ANDROID_HOME/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.kts.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
