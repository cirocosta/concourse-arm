# arch - architecture that we're targetting.
#	 possible values: armhf | arm64
#
ARG arch="arm64"


# base - contains the build tools necessary for building
#        all the dependencies
#
FROM golang AS base-armhf

	RUN set -x && \
		dpkg --add-architecture armhf && \
		apt update && apt install -y \
			git gcc-arm-linux-gnueabihf libseccomp-dev:armhf
 	ENV \
		CC=arm-linux-gnueabihf-gcc \
		CGO_ENABLED=1 \
		GOARCH=arm \
		GOARM=7 \
		GOOS=linux \
		PKG_CONFIG_LIBDIR=/usr/lib/arm-linux-gnueabihf/pkgconfig


FROM golang AS base-arm64

	RUN set -x && \
		dpkg --add-architecture arm64 && \
		apt update && apt install -y \
			git gcc-aarch64-linux-gnu libseccomp-dev:arm64
 	ENV \
		CC=aarch64-linux-gnu-gcc \
		CGO_ENABLED=1 \
		GOARCH=arm64 \
		GOOS=linux \
		PKG_CONFIG_LIBDIR=/usr/lib/aarch64-linux-gnu/pkgconfig


FROM golang AS base-native

	RUN set -x && \
		dpkg --add-architecture arm64 && \
		apt update && apt install -y \
			git gcc libseccomp-dev
 	ENV CGO_ENABLED=1


# runc -
#
FROM base-${arch} AS runc-build

	COPY ./src/github.com/opencontainers/runc ./src/github.com/opencontainers/runc
	WORKDIR /go/src/github.com/opencontainers/runc

	RUN go build \
		-ldflags "-X main.gitCommit=dirty -X main.version=1.0.0-rc8+dev -extldflags '-static'" \
		-o /usr/local/bin/runc \
		-tags "seccomp" \
		-v \
		.


# gdn - 
#
FROM base-${arch} AS gdn-base

	COPY ./src/guardian /src
	WORKDIR /src


FROM gdn-base AS gdn-build

	RUN go build \
		-tags netgo \
		-ldflags "-extldflags '-static'" \
		-o /usr/local/bin/gdn \
		./cmd/gdn

FROM gdn-base AS gdn-dadoo-build

	RUN go build \
		-tags netgo \
		-ldflags "-extldflags '-static'" \
		-o /usr/local/bin/gdn-dadoo \
		./cmd/dadoo

FROM gdn-base AS gdn-init-build

	RUN set -x && \
		cd cmd/init && \
		$CC -static -o /usr/local/bin/gdn-init \
			init.c ignore_sigchild.c


# concourse - 
#
FROM base-${arch} AS concourse-base

	COPY ./src/concourse /src
	WORKDIR /src


FROM concourse-base AS concourse-build

	RUN go build \
		-tags netgo \
		-ldflags "-extldflags '-static'" \
		-o /usr/local/bin/concourse \
		./cmd/concourse

FROM concourse-base AS fly-build

	RUN go build \
		-tags netgo \
		-ldflags "-extldflags '-static'" \
		-o /usr/local/bin/fly \
		./fly


# binaries - aggregates all of the binaries generated by
#	     previous steps.
#
FROM scratch AS binaries

	COPY --from=concourse-build 	/usr/local/bin/concourse 	/usr/local/concourse/bin/concourse
	COPY --from=fly-build 		/usr/local/bin/fly 		/usr/local/concourse/bin/fly
	COPY --from=runc-build 		/usr/local/bin/runc 		/usr/local/concourse/bin/runc
	COPY --from=gdn-build 		/usr/local/bin/gdn 		/usr/local/concourse/bin/gdn
	COPY --from=gdn-dadoo-build 	/usr/local/bin/gdn-dadoo	/usr/local/concourse/bin/gdn-dadoo
	COPY --from=gdn-init-build 	/usr/local/bin/gdn-init		/usr/local/concourse/bin/gdn-init


# registry-image -
#
FROM base-${arch} AS registry-image-resource-build

	COPY ./src/registry-image-resource /src
	WORKDIR /src

	RUN go mod download
	RUN go build -ldflags "-extldflags '-static'" -o /assets/in 	./cmd/in
	RUN go build -ldflags "-extldflags '-static'" -o /assets/out 	./cmd/out
	RUN go build -ldflags "-extldflags '-static'" -o /assets/check 	./cmd/check



FROM arm64v8/ubuntu:bionic AS rootfs-arm64
FROM arm32v7/ubuntu:bionic AS rootfs-armhf


# builder -
#
FROM base-${arch} AS img-build

	COPY ./src/img /src
	WORKDIR /src

	RUN go mod download
	RUN go build \
		-tags "seccomp noembed" \
		-ldflags "-extldflags '-static'" \
		-o /assets/img

FROM rootfs-${arch} AS builder-task-image

	COPY --from=img-build 	/assets/img 		/usr/local/bin/img
	COPY --from=runc-build 	/usr/local/bin/runc 	/usr/local/bin/runc
	COPY ./src/builder-task/build /usr/bin/build

	RUN apt update -y && \
		apt install -y ca-certificates rsync jq && \
		rm -rf /var/lib/apt/lists/*


# registry-image-resource-${arch} - the final representation of the registry-image
# 			    	    Concourse resource type.
#
FROM rootfs-${arch} AS registry-image-resource

	COPY --from=registry-image-resource-build \
		/assets/ \
		/opt/resource/

	RUN apt update -y && \
		apt install -y ca-certificates && \
		rm -rf /var/lib/apt/lists/*
