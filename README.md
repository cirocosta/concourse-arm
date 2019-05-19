# concourse-arm

Run [`concourse`](https://concourse-ci.org) workers using ARM devices (yep, including your Raspberry Pi!)


## what's inside?

A slightly modified version of Concourse, having just a single resource type ([`registry-image`](https://github.com/concourse/registry-image-resource)).


## installing

### using Docker

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

- [v5.2.0 armhf](https://github.com/cirocosta/concourse-arm/releases/download/v5.2.0/concourse-armhf.tgz)
- [v5.2.0 arm64](https://github.com/cirocosta/concourse-arm/releases/download/v5.2.0/concourse-arm64.tgz)


## building from source

1. clone this repo with all submodules

```
git clone https://github.com/cirocosta/concourse-arm --recurse-submodules -j2
```

2. the `cirocosta/concourse-arm:(arm64|armhf)` images

```
make images -j4
```

