plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.freesoftware.keyel.wear"
    compileSdk = 36

    defaultConfig {
        // Bundled wearable apps share the handheld application id; the APK is
        // extracted on the watch and never installed on the phone.
        applicationId = "com.freesoftware.keyel"
        // Wear OS 2 and later. Built as a separate APK with
        // `./gradlew :wear:assembleRelease`.
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.10.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    // Paired-device transport. Google Play Services encrypts the channel; the
    // seed is additionally encrypted at rest with a Keystore-backed master key.
    implementation("com.google.android.gms:play-services-wearable:19.0.0")
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
    implementation("androidx.core:core-ktx:1.16.0")

    testImplementation("junit:junit:4.13.2")
}
