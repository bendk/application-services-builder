FROM ubuntu:20.04

MAINTAINER Ben Dean-Kawamura "bdk@mozilla.com"

# Configuration
ENV ANDROID_BUILD_TOOLS "30.0.3"
ENV ANDROID_PLATFORM_VERSION "30"
ENV ANDROID_NDK_VERSION "21.3.6528147"
ENV TERM dumb
ENV GRADLE_OPTS -Xmx4096m -Dorg.gradle.daemon=false
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8


# System.
RUN apt-get update -qq \
    && apt-get install -qy --no-install-recommends \
        openjdk-11-jdk \
        # NSS build system.
        gyp ninja-build \
        # NSS dependency.
        zlib1g-dev \
        # SQLCipher build system.
        make \
        # SQLCipher dependency.
        tclsh \
        git \
        g++ \
        python3 \
        python-is-python3 \
        # Required to fetch/extract the Android SDK/NDK.
        curl \
        unzip \
        maven \
    && apt-get clean

# Download dependencies
COPY sha256sums /sha256sums
RUN mkdir /downloads \
    && curl -sfSL --retry 5 --retry-delay 10 https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip -o /downloads/commandlinetools.zip \
    && curl -sfSL --retry 5 --retry-delay 10 https://github.com/pinterest/ktlint/releases/download/0.43.0/ktlint -o /downloads/ktlint \
    && cd /downloads \
    && sha256sum --quiet -c /sha256sums

# Android SDK
ENV ANDROID_SDK_HOME /android-sdk
ENV ANDROID_HOME $ANDROID_SDK_HOME
RUN mkdir -p $ANDROID_SDK_HOME
ENV PATH ${PATH}:${ANDROID_SDK_HOME}/cmdline-tools/latest/bin:${ANDROID_SDK_HOME}/platform-tools:/opt/tools:${ANDROID_SDK_HOME}/build-tools/${ANDROID_BUILD_TOOLS}

# Download the Android SDK tools, unzip them to ${ANDROID_SDK_HOME}/cmdline-tools/latest/, accept all licenses
# The download link comes from https://developer.android.com/studio/#downloads
RUN cd /downloads \
    && unzip -q commandlinetools.zip \
    && mkdir $ANDROID_SDK_HOME/cmdline-tools \
    && mv cmdline-tools $ANDROID_HOME/cmdline-tools/latest \
    && mkdir -p $ANDROID_SDK_HOME/.android/ \
    && touch $ANDROID_SDK_HOME/.android/repositories.cfg \
    && yes | sdkmanager --licenses \
    && sdkmanager --verbose "platform-tools" \
        "platforms;android-${ANDROID_PLATFORM_VERSION}" \
        "build-tools;${ANDROID_BUILD_TOOLS}" \
        "extras;android;m2repository" \
        "extras;google;m2repository" \
        "ndk;21.3.6528147"

# Install robolectric packages.
RUN mvn dependency:get -Dartifact=org.robolectric:android-all:7.0.0_r1-robolectric-r1 \
    && mvn dependency:get -Dartifact=org.robolectric:android-all:8.0.0_r4-robolectric-r1 \
    && mvn dependency:get -Dartifact=org.robolectric:android-all:8.1.0-robolectric-4611349 \
    && mvn dependency:get -Dartifact=org.robolectric:android-all:9-robolectric-4913185-2

# Rust
COPY rustup.sh /rustup.sh
RUN /rustup.sh -y

# Misc
RUN cp /downloads/ktlint /usr/local/bin/ktlint && chmod a+x /usr/local/bin/ktlint
RUN mkdir -p /root/.m2/repository/org/ && ln -s /build/m2-mozilla /root/.m2/repository/org/mozilla

# Setup the entrypoint
COPY entry.sh setup-local-versions.py *.local.properties /
RUN mkdir /build
WORKDIR /build
ENTRYPOINT ["/entry.sh"]
