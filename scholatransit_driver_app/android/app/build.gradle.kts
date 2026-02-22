import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
}

// Load local.properties for secrets (gitignored)
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.inputStream())
}
val mapboxAccessToken = localProperties.getProperty("MAPBOX_ACCESS_TOKEN", "")

android {
    namespace = "com.scholatransit.driver.scholatransit_driver_app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    // Mapbox configuration
    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.scholatransit.driver.scholatransit_driver_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Mapbox token - from local.properties (add MAPBOX_ACCESS_TOKEN=your_token there)
        buildConfigField("String", "MAPBOX_ACCESS_TOKEN", "\"$mapboxAccessToken\"")
        resValue("string", "mapbox_access_token", mapboxAccessToken.ifEmpty { "YOUR_MAPBOX_ACCESS_TOKEN" })

        // Graphics and memory optimizations
        // Note: ABI filters are managed by Flutter when using --split-per-abi
        // Remove the ndk block below if you want Flutter to manage ABIs automatically
        // ndk {
        //     abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        // }

        // Increase heap size to handle graphics buffer issues
        manifestPlaceholders["android:largeHeap"] = "true"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Disable ART profile compilation to avoid baseline-prof.txt errors
// This is done via Gradle task configuration since the property was removed in AGP 8.0+
afterEvaluate {
    tasks.matching { it.name.contains("ArtProfile", ignoreCase = true) }.configureEach {
        enabled = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))
    
    // Firebase products
    // When using the BoM, don't specify versions in Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-firestore")
    
    // Add the dependencies for any other desired Firebase products
    // https://firebase.google.com/docs/android/setup#available-libraries
}
