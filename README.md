# Application Services Builder

*A docker image for building application-services and related components.*

This repository builds a docker image that can build `application-services`, `android-components`, and `fenix`.  We use it to make "nightly" builds that that contain in-progress work with changes to multiple repos.  For example:

  - We have non-breaking changes in `application-services:main` and we want to test building that against `android-components:main` and `fenix:main`
  - We have breaking changes in `application-services:main` and we want to test building that against branches in `android-components` and/or `fenix`
  - We have changes in an `application-services` branch and want to test building that against the corresponding branches in `android-components` and/or `fenix`

This repository currently only supports `android-components` and `fenix`, but maybe it could support `firefox-ios` someday.

## Building/pushing the image

```
docker build -t bendk/application-services-builder .
docker login
docker push bendk/application-services-builder
```

## Using the image

- This image is meant to be used as part of a CI process, with each step running the image with different arguments:
  - `checkout [application-services-repo-url] [branch]`
  - `checkout [android-components-repo-url] [branch]`
  - `checkout [fenix-repo-url] [branch]`
  - `build-application-services`
  - `test-android-components`
  - `build-android-components`
  - `test-fenix`
  - `build-fenix`
- The `/build` directory contains data meant to be shared between the various steps and should be linked to a shared volume.
- This container can exceed the default number of open files.  Use the option `--ulimit nofile=5000:5000` to avoid this

If you were running locally, you would run something like this:

```
docker run --rm -v $(pwd)/build:/build:z  --ulimit nofile=5000:5000 -- bendk/application-services-builder checkout [application-services-repo-url] [branch]
docker run --rm -v $(pwd)/build:/build:z  --ulimit nofile=5000:5000 -- bendk/application-services-builder checkout [android-components-repo-url] [branch]
docker run --rm -v $(pwd)/build:/build:z  --ulimit nofile=5000:5000 -- bendk/application-services-builder checkout [fenix-repo-url] [branch]
docker run --rm -v $(pwd)/build:/build:z  --ulimit nofile=5000:5000 -- bendk/application-services-builder build-application-services
docker run --rm -v $(pwd)/build:/build:z  --ulimit nofile=5000:5000 -- bendk/application-services-builder test-android-components
docker run --rm -v $(pwd)/build:/build:z  --ulimit nofile=5000:5000 -- bendk/application-services-builder build-android-components
docker run --rm -v $(pwd)/build:/build:z  --ulimit nofile=5000:5000 -- bendk/application-services-builder test-fenix
docker run --rm -v $(pwd)/build:/build:z  --ulimit nofile=5000:5000 -- bendk/application-services-builder build-fenix
```

This would result in the Fenix APKs in `build/fenix/app/build/outputs/apk/debug/`.

https://github.com/bendk/application-services-nightlies for an example of this in a CI system.
