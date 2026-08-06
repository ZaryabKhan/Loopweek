import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.appcodecraft.loopweek"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (java.time desugaring).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Pin Kotlin to the same JVM target so Java and Kotlin tasks agree.
    // Uses the running JDK (21 locally, 17 in CI) but emits JVM 17 bytecode.
    kotlinOptions {
        jvmTarget = "17"
    }

    // Reads signing creds from android/key.properties when present (gitignored).
    // Built locally for Play Store AAB uploads. CI uses repo secrets instead.
    val keyPropertiesFile = rootProject.file("key.properties")
    val keyProperties = Properties()
    if (keyPropertiesFile.exists()) {
        keyProperties.load(FileInputStream(keyPropertiesFile))
    }
    val hasSigning = keyProperties.getProperty("storeFile") != null

    signingConfigs {
        if (hasSigning) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.appcodecraft.loopweek"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Sign with the release key when available; fall back to debug
            // so `flutter run --release` works without a keystore for contributors
            // and CI runs that aren't the release workflow.
            signingConfig =
                if (hasSigning) signingConfigs.getByName("release")
                else signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
