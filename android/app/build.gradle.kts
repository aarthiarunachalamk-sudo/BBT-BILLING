plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.smartbilling360.bbt_billing"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.smartbilling360.bbt_billing"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Keep a stable, easily shareable release artifact name.  Flutter supplies
// versionCode from pubspec.yaml (for example: 1.0.4+5 -> VERSION5).
val releaseApkName = "SUPERMARKET-BILLING-VERSION${android.defaultConfig.versionCode}.apk"
val copyNamedReleaseApk by tasks.registering(Copy::class) {
    from(rootProject.layout.projectDirectory.dir("../build/app/outputs/apk/release"))
    include("app-release.apk")
    into(rootProject.layout.projectDirectory.dir("../build/app/outputs/named-apk"))
    rename { releaseApkName }
}

// Flutter creates assembleRelease after this script is evaluated. Configure
// it lazily, so this naming step never prevents a normal release build.
tasks.configureEach {
    if (name == "assembleRelease") finalizedBy(copyNamedReleaseApk)
}
