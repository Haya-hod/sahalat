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
    id("com.android.application") version "8.9.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.15") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")

// Unity as a Library: copy the `unityLibrary` folder from Unity’s Android export
// (Build Settings → Android → Export Project) into `android/unityLibrary/`.
val unityLibraryDir = file("unityLibrary")
val unityHasGradle =
    unityLibraryDir.resolve("build.gradle").exists() ||
        unityLibraryDir.resolve("build.gradle.kts").exists()
if (unityHasGradle) {
    include(":unityLibrary")
    project(":unityLibrary").projectDir = unityLibraryDir
    // Unity 6 + AR: unityLibrary depends on this nested module (see unityLibrary/build.gradle).
    val xrManifestDir = unityLibraryDir.resolve("xrmanifest.androidlib")
    if (xrManifestDir.resolve("build.gradle").exists()) {
        include(":unityLibrary:xrmanifest.androidlib")
        project(":unityLibrary:xrmanifest.androidlib").projectDir = xrManifestDir
    }
}
