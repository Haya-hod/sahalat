plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sahalat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.sahalat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Note: Unity AR requires API 30+
        minSdk = maxOf(flutter.minSdkVersion, 30)
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

    packaging {
        jniLibs {
            // Flutter + Unity both ship native helpers; keep one copy when unityLibrary is linked.
            pickFirsts += "**/libc++_shared.so"
            pickFirsts += "**/libfbjni.so"
        }
    }
}

val unityLinked =
    rootProject.file("unityLibrary/build.gradle").exists() ||
        rootProject.file("unityLibrary/build.gradle.kts").exists()

dependencies {
    if (unityLinked) {
        implementation(project(":unityLibrary"))
    }
}

flutter {
    source = "../.."
}
