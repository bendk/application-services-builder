#!/bin/bash

set -ex

. "$HOME/.cargo/env"

# Ensure that the symlink target we setup to the build directory is present
mkdir -p /build/m2-mozilla

COMMAND=$1
shift

case $COMMAND in
    "checkout" )
        git clone --branch $2 --recurse-submodules --depth 1 -- $1
        ;;

    "setup" )
        /setup-local-versions.py
        cp /application-services.local.properties application-services/local.properties
        cp /android-components.local.properties android-components/local.properties
        cp /fenix.local.properties fenix/local.properties
        echo -e "\nallprojects { repositories { mavenLocal() } }" >> android-components/build.gradle
        # Realy ugly shell code because we need to prepend the buildscript line
        echo -e "buildscript { repositories { mavenLocal() } }\n" > fenix-build.gradle
        cat fenix/build.gradle >> fenix-build.gradle
        echo -e "\nallprojects { repositories { mavenLocal() } }" >> fenix-build.gradle
        mv fenix-build.gradle fenix/build.gradle
        ;;

    "build-application-services" )
        cd application-services
        ./gradlew publishToMavenLocal
        ;;

    "test-android-components" )
        cd android-components
        ./gradlew testDebugUnitTest
        ;;

    "build-android-components" )
        cd android-components
        ./gradlew publishToMavenLocal
        ;;

    "test-fenix" )
        cd fenix
        ./gradlew testDebugUnitTest
        ;;

    "build-fenix" )
        cd fenix
        ./gradlew assembleDebug
        ;;

    "shell" )
        bash
        ;;

    *)
        echo "Unknown command: $COMMAND"
        exit 1
    ;;
esac
