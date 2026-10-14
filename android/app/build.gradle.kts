import java.util.Properties

val farmWorldSigningProperties = Properties()
val farmWorldSigningPropertiesFile = rootProject.file("key.properties")
if (farmWorldSigningPropertiesFile.exists()) {
    farmWorldSigningPropertiesFile.inputStream().use(farmWorldSigningProperties::load)
    val requiredSigningProperties = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    val missingSigningProperties = requiredSigningProperties.filter {
        farmWorldSigningProperties.getProperty(it).isNullOrBlank()
    }
    if (missingSigningProperties.isNotEmpty()) {
        throw GradleException(
            "android/key.properties is incomplete; missing: ${missingSigningProperties.joinToString()}",
        )
    }
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.farm_world"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        create("release") {
            if (farmWorldSigningPropertiesFile.exists()) {
                storeFile = rootProject.file(farmWorldSigningProperties.getProperty("storeFile"))
                storePassword = farmWorldSigningProperties.getProperty("storePassword")
                keyAlias = farmWorldSigningProperties.getProperty("keyAlias")
                keyPassword = farmWorldSigningProperties.getProperty("keyPassword")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.farm_world"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // A release without a local upload key stays unsigned. Never ship a
            // Play Store candidate signed with Flutter's debug key.
            signingConfig = if (farmWorldSigningPropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                null
            }
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
