plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "dev.agouhmad.keyel"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.agouhmad.keyel"
        minSdk = 26
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
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // R8 code shrinking, obfuscation and resource shrinking are enabled
            // for this build type by the Flutter Gradle plugin
            // (`FlutterPluginUtils.shouldShrinkResources`), which also adds
            // `proguard-android-optimize.txt`, the Flutter embedding rules and
            // `proguard-rules.pro`. Do not set `isMinifyEnabled` here: turning it
            // on without Flutter's rule files would break the release build.
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

// ---------------------------------------------------------------------------
// Workaround for https://github.com/flutter/flutter/issues/169336
//
// Since Flutter 3.32, dev-dependency plugins (such as `integration_test`) are
// excluded from release builds. However, the shared generated file
// `GeneratedPluginRegistrant.java` is only rewritten for release mode when the
// Flutter tool's pre-generation step runs. That step is skipped for `--no-pub`
// builds and for IDE/direct Gradle builds, so a registrant produced by a debug
// build can still reference `integration_test` while Gradle omits it from the
// release classpath, failing `:app:compileReleaseJavaWithJavac`.
//
// Strip dev-dependency plugin registrations from the generated file before any
// release Java compilation so release builds are always self-consistent.
// ---------------------------------------------------------------------------
val flutterPluginsDependenciesFile = rootProject.file("../.flutter-plugins-dependencies")
val generatedPluginRegistrantFile =
    file("src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")

val stripDevDependencyPluginsForRelease =
    tasks.register("stripDevDependencyPluginsForRelease") {
        description =
            "Removes dev-dependency plugin registrations from " +
                "GeneratedPluginRegistrant.java for release builds."
        group = "flutter"

        val pluginsFile = flutterPluginsDependenciesFile
        val registrantFile = generatedPluginRegistrantFile

        doLast {
            if (!pluginsFile.exists() || !registrantFile.exists()) {
                return@doLast
            }

            @Suppress("UNCHECKED_CAST")
            val root = groovy.json.JsonSlurper().parse(pluginsFile) as? Map<String, Any?>
                ?: return@doLast
            @Suppress("UNCHECKED_CAST")
            val plugins = root["plugins"] as? Map<String, Any?> ?: return@doLast
            val androidPlugins = plugins["android"] as? List<Any?> ?: return@doLast
            val devDependencyNames =
                androidPlugins
                    .mapNotNull { entry ->
                        @Suppress("UNCHECKED_CAST")
                        val plugin = entry as? Map<String, Any?> ?: return@mapNotNull null
                        if (plugin["dev_dependency"] == true) {
                            plugin["name"] as? String
                        } else {
                            null
                        }
                    }
                    .toSet()

            if (devDependencyNames.isEmpty()) {
                return@doLast
            }

            val lines = registrantFile.readLines()
            val kept = ArrayList<String>(lines.size)
            var index = 0
            while (index < lines.size) {
                if (lines[index].trim() == "try {") {
                    var cursor = index + 1
                    var pluginName: String? = null
                    var blockEnd = -1
                    while (cursor < lines.size) {
                        val line = lines[cursor]
                        if (line.contains("Error registering plugin ")) {
                            pluginName =
                                line.substringAfter("Error registering plugin ")
                                    .substringBefore(",")
                                    .trim()
                        }
                        if (line.trim() == "}" && cursor > index + 2) {
                            blockEnd = cursor
                            break
                        }
                        cursor++
                    }
                    if (pluginName != null &&
                        pluginName in devDependencyNames &&
                        blockEnd != -1
                    ) {
                        index = blockEnd + 1
                        continue
                    }
                }
                kept.add(lines[index])
                index++
            }

            if (kept.size != lines.size) {
                registrantFile.writeText(kept.joinToString("\n") + "\n")
            }
        }
    }

tasks.matching {
    it.name.startsWith("compileRelease") && it.name.endsWith("JavaWithJavac")
}.configureEach {
    dependsOn(stripDevDependencyPluginsForRelease)
}
