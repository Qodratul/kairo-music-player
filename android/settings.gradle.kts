try {
    val processEnvironmentClass = Class.forName("java.lang.ProcessEnvironment")
    listOf("theCaseInsensitiveEnvironment", "theEnvironment", "theUnmodifiableEnvironment").forEach { fieldName ->
        try {
            val field = processEnvironmentClass.getDeclaredField(fieldName)
            field.isAccessible = true
            val map = field.get(null)
            if (map is MutableMap<*, *>) {
                map.keys.removeIf { key -> key.toString().equals("ANDROID_PREFS_ROOT", ignoreCase = true) }
            }
        } catch (_: Throwable) {
        }
    }
} catch (_: Throwable) {
}

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
