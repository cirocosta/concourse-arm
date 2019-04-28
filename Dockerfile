# base - contains the build tools necessary for building
#        all the dependencies
#
FROM golang AS base

	RUN set -x && \
		dpkg --add-architecture armhf && \
		apt update && \
		apt install -y \
			git gcc-arm-linux-gnueabihf
 	ENV \
		CC=arm-linux-gnueabihf-gcc \
		CGO_ENABLED=1 \
		GOARCH=arm \
		GOARM=7 \
		GOOS=linux \
		PKG_CONFIG_LIBDIR=/usr/lib/arm-linux-gnueabihf/pkgconfig



# runc -
#
FROM base AS runc-build

	RUN apt update && apt install -y \
		make libseccomp-dev:armhf

	COPY ./src/github.com/opencontainers/runc ./src/github.com/opencontainers/runc
	WORKDIR /go/src/github.com/opencontainers/runc

	RUN go build \
		-ldflags "-X main.gitCommit=dirty -X main.version=1.0.0-rc8+dev" \
		-o runc \
		-tags "seccomp" \
		-v \
		.


# gdn - 
#
FROM base AS gdn-base

	COPY ./src/guardian /src
	WORKDIR /src


FROM gdn-base AS gdn-build

	RUN go build \
		-tags netgo \
		-o /usr/local/bin/gdn \
		./cmd/gdn

FROM gdn-base AS gdn-dadoo-build

	RUN go build \
		-tags netgo \
		-o /usr/local/bin/gdn-dadoo \
		./cmd/gdn

FROM gdn-base AS gdn-init-build

	RUN set -x && \
		cd cmd/init && \
		$CC -o /usr/local/bin/gdn-init \
			init.c ignore_sigchild.c


# concourse - 
#
FROM base AS concourse-base

	COPY ./src/concourse /src
	WORKDIR /src


FROM concourse-base AS concourse-build

	RUN go build \
		-tags netgo \
		-o /usr/local/bin/concourse \
		./cmd/concourse

FROM concourse-base AS fly-build

	RUN go build \
		-tags netgo \
		-o /usr/local/bin/fly \
		./fly


FROM scratch AS release

	COPY --from=concourse-build 		/usr/local/bin/concourse 	/usr/local/concourse/bin/concourse
	COPY --from=fly-build 			/usr/local/bin/fly 		/usr/local/concourse/bin/fly
	COPY --from=runc-build 			/usr/local/bin/runc 		/usr/local/concourse/bin/runc
	COPY --from=gdn-build 			/usr/local/bin/gdn 		/usr/local/concourse/bin/gdn
	COPY --from=gdn-dadoo-build 		/usr/local/bin/gdn-dadoo	/usr/local/concourse/bin/gdn-dadoo
	COPY --from=gdn-init-build 		/usr/local/bin/gdn-init		/usr/local/concourse/bin/gdn-init

