plugins {
    `maven-publish`
}

group = "io.github.mirrgieriana"
version = providers.environmentVariable("VERSION").getOrElse("0.0.0")

publishing {
    publications {
        create<MavenPublication>("maven") {
            artifactId = "ifr25ku-server-portable"
            artifact(file(".xarpite/maven/io/github/mirrgieriana/ifr25ku-server-portable/0.0.0/ifr25ku-server-portable-0.0.0.xa1")) {
                extension = "xa1"
            }
        }
    }
    repositories {
        maven {
            url = uri(layout.buildDirectory.dir("maven-repo"))
        }
    }
}
