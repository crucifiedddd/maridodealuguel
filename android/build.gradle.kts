// android/build.gradle.kts

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Mantém o esquema de buildDir do template Flutter (não é obrigatório, mas ok)
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// Task 'clean' única (remova duplicadas)
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
