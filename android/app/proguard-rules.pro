# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Suppress warnings for TensorFlow Lite GPU classes that may not be available on all devices
-dontwarn org.tensorflow.lite.gpu.**
-dontwarn org.tensorflow.lite.nnapi.**
-dontwarn org.tensorflow.lite.delegates.**

# TensorFlow Lite keep rules - Keep all classes and their members
-keep class org.tensorflow.lite.** { *; }
-keep interface org.tensorflow.lite.** { *; }

# Keep all TensorFlow Lite GPU related classes and interfaces
-keep class org.tensorflow.lite.gpu.** { *; }
-keep interface org.tensorflow.lite.gpu.** { *; }
-keep enum org.tensorflow.lite.gpu.** { *; }

# Keep TensorFlow Lite delegates
-keep class org.tensorflow.lite.delegates.** { *; }
-keep interface org.tensorflow.lite.delegates.** { *; }

# Keep TensorFlow Lite NNAPI classes
-keep class org.tensorflow.lite.nnapi.** { *; }
-keep interface org.tensorflow.lite.nnapi.** { *; }

# Specifically keep GPU Delegate classes
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$* { *; }
-keep class org.tensorflow.lite.gpu.CompatibilityList { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegate { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegate$* { *; }

# Keep TensorFlow Lite Flex Delegate (if using)
-keep class org.tensorflow.lite.flex.** { *; }

# Keep all nested classes and inner classes
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep native methods and JNI interfaces
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep TensorFlow Lite model loading classes
-keep class org.tensorflow.lite.Interpreter { *; }
-keep class org.tensorflow.lite.Interpreter$* { *; }
-keep class org.tensorflow.lite.InterpreterApi { *; }
-keep class org.tensorflow.lite.InterpreterApi$* { *; }

# Keep annotation classes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations

# Keep Enum methods
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# TensorFlow Lite support classes
-keep class org.tensorflow.lite.support.** { *; }
-keep class org.tensorflow.lite.task.** { *; }

# Keep classes referenced by TensorFlow Lite
-keep class java.nio.** { *; }
-keep class java.lang.reflect.** { *; }

# Flutter specific rules for TensorFlow Lite
-keep class io.flutter.plugins.** { *; }

# Additional rules for tflite_flutter plugin
-keep class org.dartlang.** { *; }

# Keep all classes that might be referenced by TensorFlow Lite at runtime
-keepclassmembers class * {
    @org.tensorflow.lite.annotations.UsedByReflection *;
}

# Additional aggressive keep rules for TensorFlow Lite
-keepnames class org.tensorflow.lite.** { *; }
-keepclassmembernames class org.tensorflow.lite.** { *; }
