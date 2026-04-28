allprojects {
    repositories {
        google()
        mavenCentral()
        val unityLibs = rootProject.projectDir.resolve("unityLibrary/libs")
        if (unityLibs.isDirectory) {
            flatDir { dirs(unityLibs) }
        }
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
    // :unityLibrary and its nested modules must not evaluationDependOn :app.
    val isUnityTree =
        project.path == ":unityLibrary" || project.path.startsWith(":unityLibrary:")
    if (!isUnityTree) {
        project.evaluationDependsOn(":app")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
