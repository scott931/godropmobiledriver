plugins {
    // Add the dependency for the Google services Gradle plugin
    id("com.google.gms.google-services") version "4.4.4" apply false
}

// Load local.properties for Mapbox downloads token (gitignored)
val rootLocalProperties = java.util.Properties()
val rootLocalPropertiesFile = file("local.properties")
if (rootLocalPropertiesFile.exists()) {
    rootLocalProperties.load(rootLocalPropertiesFile.inputStream())
}
val mapboxDownloadsToken = rootLocalProperties.getProperty("MAPBOX_DOWNLOADS_TOKEN")

allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            credentials {
                username = "mapbox"
                password = mapboxDownloadsToken
            }
            authentication {
                create<BasicAuthentication>("basic")
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Fix for record package namespace issue
subprojects {
    if (project.name == "record") {
        // Configure namespace for record package to fix AGP 8+ compatibility
        val configureNamespace: () -> Unit = {
            val android = extensions.findByName("android")
            if (android != null) {
                try {
                    // Try to use the typed extension first
                    extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
                        namespace = "com.llfbandit.record"
                    }
                } catch (e: Exception) {
                    // Fallback: use reflection
                    try {
                        val setNamespaceMethod = android.javaClass.getMethod("setNamespace", String::class.java)
                        setNamespaceMethod.invoke(android, "com.llfbandit.record")
                    } catch (e2: Exception) {
                        try {
                            val namespaceField = android.javaClass.getDeclaredField("namespace")
                            namespaceField.setAccessible(true)
                            namespaceField.set(android, "com.llfbandit.record")
                        } catch (e3: Exception) {
                            // Silently fail if all methods don't work
                        }
                    }
                }
            }
        }
        
        // Try to configure when plugin is applied
        plugins.withId("com.android.library") {
            configureNamespace()
        }
        
        // Also configure after project evaluation (if not already evaluated)
        try {
            project.afterEvaluate {
                configureNamespace()
            }
        } catch (e: IllegalStateException) {
            // Project already evaluated, configure now
            configureNamespace()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
