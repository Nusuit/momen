import com.android.build.gradle.LibraryExtension

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

// AGP 8+ requires every Android library module to declare a namespace.
// Some older Flutter plugins in pub cache still omit it and fail the build.
subprojects {
    plugins.withId("com.android.library") {
        val androidExt = project.extensions.findByName("android")
        if (androidExt is LibraryExtension && androidExt.namespace.isNullOrBlank()) {
            androidExt.namespace = "autofix.${project.name.replace('-', '_')}"
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
