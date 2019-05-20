# concourse-arm

Run [`concourse`](https://concourse-ci.org) workers using ARM devices (yep, including your Raspberry Pi!)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [what's inside?](#whats-inside)
- [installing](#installing)
  - [using Docker](#using-docker)
  - [binaries](#binaries)
- [building from source](#building-from-source)
  - [dependencies](#dependencies)
  - [steps](#steps)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## what's inside?

A slightly modified version of Concourse, having just a single resource type ([`registry-image`](https://github.com/concourse/registry-image-resource)).


## installing

`concourse-arm` is provided in two flavors:

- container images (see ["using docker"](#using-docker)), and
- raw binaries (see ["binaries"](#binaries))


### using docker

Images are published with the `platform` already according to the platform.

```
docker pull cirocosta/concourse-arm:5.2.0
```

If you need/want to be more explicit, there are also tagged versions:

```
docker pull cirocosta/concourse-arm:5.2.0-armhf
docker pull cirocosta/concourse-arm:5.2.0-arm64
```

With the image present, the standard Docker configurations that you can find under [`concourse/concourse-docker`](https://github.com/concourse/concourse-docker) apply.

The tl;dr for having a single worker that has the right keys under `/tmp/keys`:

```sh
docker run \
		--detach \
		--privileged \
		--stop-signal=SIGUSR2 \
		--volume /tmp/keys:/concourse-keys:ro \
		cirocosta/concourse-arm:5.2.0-arm64 \
		worker \
		--name=arm64 \
		--tag=arm \
		--tsa-host=hush-house.pivotal.io:2222
```


### binaries

Just like you'd [install the regular AMD64 version of Concourse](https://concourse-ci.org/install.html#install), all that's needed is placing the contents of the gzipped tarball into `/usr/local`:

```
tar -zxvf concourse-*.tgz -C /usr/local
```

- [v5.2.0 armhf](https://github.com/cirocosta/concourse-arm/releases/download/v5.2.0/concourse-armhf.tgz)
- [v5.2.0 arm64](https://github.com/cirocosta/concourse-arm/releases/download/v5.2.0/concourse-arm64.tgz)


## building from source

All of the source code necessary for building `concourse-arm` is packed in the this repository by leveraging [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules).

| component      | build status |
| -------------- | ------------ |
| builder        | ![](https://hush-house.pivotal.io/api/v1/teams/main/pipelines/concourse-arm/jobs/builder/badge) |
| registry-image | ![](https://hush-house.pivotal.io/api/v1/teams/main/pipelines/concourse-arm/jobs/builder/registry-image-resource) |
| concourse      | ![](https://hush-house.pivotal.io/api/v1/teams/main/pipelines/concourse-arm/jobs/builder/concourse) |


### dependencies

Regardless of the desired output (container images or binaries), the process of building the components require something that can build Dockerfiles (either Docker itself or other builders like [buildkit](https://github.com/moby/buildkit), [img](https://github.com/genuinetools/img) or anything like that).

The only hard requirement is that when building targets that require running steps that execute ARM-based binaries, the ability to run those is essential ([Docker for Mac](https://docs.docker.com/docker-for-mac/install/) makes that super easy, but a combination of `binfmt_misc` and `qemu-user-static` also works).

### steps

1. clone this repo with all submodules

```
git clone https://github.com/cirocosta/concourse-arm --recurse-submodules -j2
```

2. build the `cirocosta/concourse-arm:(arm64|armhf)` container images

```
make images -j4
```

If everything went all right, this is what you'll end up with:

```
build
├── arm64
│   ├── concourse
│   │   ├── bin
│   │   │   ├── concourse
│   │   │   ├── fly
│   │   │   ├── gdn
│   │   │   ├── gdn-dadoo
│   │   │   ├── gdn-init
│   │   │   └── runc
│   │   └── resource-types
│   │       └── registry-image
│   │           ├── resource_metadata.json
│   │           └── rootfs.tgz
│   └── concourse.tgz
└── armhf
    ├── concourse
    │   ├── bin
    │   │   ├── concourse
    │   │   ├── fly
    │   │   ├── gdn
    │   │   ├── gdn-dadoo
    │   │   ├── gdn-init
    │   │   └── runc
    │   └── resource-types
    │       └── registry-image
    │           ├── resource_metadata.json
    │           └── rootfs.tgz
    └── concourse.tgz
```

ps.: building the container images will involve generating binaries and resource types under `./build` for each supported architecture.


## license

See [the LICENSE file](./LICENSE).

