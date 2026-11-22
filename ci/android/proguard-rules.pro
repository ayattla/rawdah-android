# قواعد R8 لروضة: تصغير الكود وإخفاء أسمائه مع حماية ما يُستدعى بالانعكاس (reflection).

# ---- Flutter: محرك التشغيل وقنوات الإضافات
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.embedding.**
# مكونات Play المؤجلة لا يستخدمها التطبيق، لكن Flutter يشير إليها
-dontwarn com.google.android.play.core.**

# ---- Firebase (Auth + Firestore): نماذج البيانات و gRPC
-keep class com.google.firebase.** { *; }
-keep class io.grpc.** { *; }
-keepattributes Signature, *Annotation*, InnerClasses, EnclosingMethod
-dontwarn io.grpc.**
-dontwarn com.google.firebase.**
-dontwarn org.checkerframework.**
-dontwarn javax.annotation.**

# ---- النطق (flutter_tts) يتصل بمحرك TextToSpeech في النظام
-keep class com.tundralabs.fluttertts.** { *; }
-keep class android.speech.tts.** { *; }

# ---- التخزين المشفّر (flutter_secure_storage) يعتمد على Tink و Android Keystore
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
-dontwarn com.google.errorprone.annotations.**

# ---- Flame محرك ألعاب مكتوب بلغة Dart بالكامل، فلا يحتاج قواعد Java.
# الكود الذي يُصغَّر هنا هو طبقة أندرويد الأصلية فقط؛ كود Dart يُترجم AOT ويُصغَّر بـ --obfuscate.

# إزالة سجلات التصحيح من النسخة النهائية
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
}
