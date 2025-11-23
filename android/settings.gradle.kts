// android/settings.gradle.kts

pluginManagement {
    // Integração com o Flutter (lê o caminho do SDK do Flutter)
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
    // Loader do Flutter (obrigatório no settings)
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // Plugins de Android e Kotlin (somente versões aqui; 'apply false')
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false

    // Firebase Google Services (somente versão aqui; 'apply false')
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
