buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Provide the Android Gradle Plugin on the root buildscript classpath so we
        // can reference its typed extension (com.android.build.gradle.BaseExtension)
        // to reliably override each plugin subproject's compileSdk below. Must match
        // the AGP version declared in settings.gradle.kts.
        classpath("com.android.tools.build:gradle:9.1.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Force a modern compileSdk on every Android plugin subproject. Some plugins
// (e.g. keyboard_height_plugin) still hardcode an old compileSdk (31), but their
// transitive AndroidX dependencies (fragment 1.7.1, activity 1.8.1, core 1.13.1,
// etc.) require compiling against API 34+. That mismatch fails the build at
// ":<plugin>:checkReleaseAarMetadata" / "checkDebugAarMetadata" with
// "requires ... compile against version 34 or later ... currently compiled
// against android-31". We raise any subproject's compileSdk below 36 up to 36.
// This is registered via plugins.withId so it runs when each subproject applies
// the Android Gradle Plugin, avoiding "afterEvaluate when already evaluated"
// errors caused by the evaluationDependsOn(":app") hook below. The Android
// extension is accessed reflectively so the root buildscript does not need the
// Android Gradle Plugin on its classpath.
val enforcedCompileSdk = 36
subprojects {
    // Within afterEvaluate, react to the Android plugin and reconfigure the
    // BaseExtension. Using configure<BaseExtension> at this point is the correct
    // window to raise compileSdk (setting it during plugin-apply is either too
    // early — the plugin's own build.gradle overwrites it — or, via a plain
    // afterEvaluate call, too late: "It is too late to set compileSdk").
    afterEvaluate {
        plugins.withType<com.android.build.gradle.BasePlugin> {
            configure<com.android.build.gradle.BaseExtension> {
                val current = (compileSdkVersion ?: "android-1").substringAfterLast('-').toIntOrNull() ?: 1
                if (current < enforcedCompileSdk) {
                    compileSdkVersion(enforcedCompileSdk)
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Some plugins (e.g. flutter_timezone) still target an older JVM for their
// Kotlin tasks (1.8) while their Java tasks use 11/17, which Gradle rejects with
// "Inconsistent JVM Target Compatibility Between Java and Kotlin Tasks". The
// Kotlin-side mismatch is downgraded from error to warning via the Gradle
// property "kotlin.jvm.target.validation.mode=warning" in gradle.properties.
// We additionally align every subproject's Java compilation to JVM 17 so the
// bytecode stays consistent with the app module.
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
