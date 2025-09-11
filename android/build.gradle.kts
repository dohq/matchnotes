allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Google Services / Crashlytics Gradle plugins（Kotlin DSL）
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // バージョンは Gradle に解決させます（Flutter 推奨の互換範囲内）
        classpath("com.google.gms:google-services:+")
        classpath("com.google.firebase:firebase-crashlytics-gradle:+")
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
