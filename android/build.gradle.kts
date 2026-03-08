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
subprojects {
    project.evaluationDependsOn(":app")
}

// Fix for plugins that don't declare a namespace (required by AGP 8+)
subprojects {
    val applyNamespaceFix: (Project) -> Unit = { proj ->
        if (proj.hasProperty("android")) {
            val android = proj.extensions.findByName("android")
            if (android is com.android.build.gradle.LibraryExtension) {
                if (android.namespace.isNullOrEmpty()) {
                    android.namespace = proj.group.toString().ifEmpty {
                        "com.nateshmbhat.credit_card_scanner"
                    }
                }
            }
        }
    }
    if (project.state.executed) {
        applyNamespaceFix(project)
    } else {
        afterEvaluate {
            applyNamespaceFix(project)
        }
    }
}

// Fix JVM target compatibility between Java and Kotlin tasks
subprojects {
    val applyJvmFix: (Project) -> Unit = { proj ->
        // 1. Force Java extension
        proj.plugins.withId("java") {
            val javaPlugin = proj.extensions.findByType<JavaPluginExtension>()
            if (javaPlugin != null) {
                javaPlugin.sourceCompatibility = JavaVersion.VERSION_17
                javaPlugin.targetCompatibility = JavaVersion.VERSION_17
            }
        }
        
        // 2. Force Android extension
        if (proj.hasProperty("android")) {
            val androidExt = proj.extensions.findByName("android")
            if (androidExt is com.android.build.gradle.BaseExtension) {
                try {
                    androidExt.compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_17
                        targetCompatibility = JavaVersion.VERSION_17
                    }
                } catch (e: Exception) {
                    // Ignore if already finalized
                }
            }
        }
        
        // 3. Force Kotlin tasks explicitly
        proj.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
        
        // 4. Force JavaCompile explicitly (to match Kotlin side)
        proj.tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
    }
    
    if (project.state.executed) {
        applyJvmFix(project)
    } else {
        afterEvaluate {
            applyJvmFix(project)
        }
    }
}

// Add this block to fix kotlin-stdlib missing in plugins when upgrading kotlin
subprojects {
    project.configurations.configureEach {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                // Ensure all standard library components use version 2.1.0
                useVersion("2.1.0")
            }
        }
    }
}

// Workaround for card_scanner failing to compile on Kotlin 2.1 due to removed `toLowerCase`
subprojects {
    if (project.name == "card_scanner") {
         project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                // Force Language Version to 1.9 where toLowerCase is still allowed (deprecated but not removed)
                languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_9)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
