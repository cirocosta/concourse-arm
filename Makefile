GOLANG_BUILD_FLAGS = -tags netgo -ldflags '-w -extldflags "-static"'
BUILD_DIR = /usr/local/concourse


# produces a tarball for installing concourse.
#
# .
# ├── bin
# │   ├── concourse
# │   └── gdn
# ├── fly-assets
# │   ├── fly-darwin-amd64.tgz
# │   ├── fly-linux-amd64.tgz
# │   └── fly-windows-amd64.zip
# └── resource-types
#     └── git
# 	├── resource_metadata.json
# 	└── rootfs.tgz
#
rc: | fly concourse gdn resource-types runc
	mkdir -p linux-rc
	tar -czvf ./linux-rc/concourse.tgz -C /tmp ./concourse


run:
	CONCOURSE_GARDEN_ALLOW_HOST_ACCESS=true \
	CONCOURSE_GARDEN_LOG_LEVEL=debug \
	CONCOURSE_GARDEN_INIT_BIN=$(BUILD_DIR)/bin/gdn-init \
	CONCOURSE_GARDEN_RUNTIME_PLUGIN=$(BUILD_DIR)/bin/gdn-runc \
	CONCOURSE_GARDEN_DADOO_BIN=$(BUILD_DIR)/bin/gdn-dadoo \
		sudo -E $(BUILD_DIR)/bin/concourse worker \
			--name=raspberry-pi \
			--resource-types=$(BUILD_DIR)/resource-types \
			--tag=arm \
			--tsa-host=hush-house.pivotal.io:2222 \
			--tsa-public-key=tsa-public-key \
			--tsa-worker-private-key=./key \
			--work-dir=/tmp



resource-types: registry-image-resource



# builds fly
#
fly: 
	cd ./src/concourse/fly && \
		CGO_ENABLED=0 \
			go build -v \
			$(GOLANG_BUILD_FLAGS) \
			-o $(BUILD_DIR)/fly-assets/fly \
			.

# builds concourse
#
concourse:
	cd ./src/concourse && \
		go build -v \
		$(GOLANG_BUILD_FLAGS) \
		-o $(BUILD_DIR)/bin/concourse \
		./cmd/concourse

# builds runc
#
runc:
	mkdir -p $(BUILD_DIR)/bin
	export GOPATH=$(shell pwd) && \
		cd ./src/github.com/opencontainers/runc && \
			make BUILDTAGS="seccomp" && \
			cp -f ./runc $(BUILD_DIR)/bin/gdn-runc
		
	
# build gdn
#
gdn: gdn-cmd gdn-init gdn-dadoo


gdn-cmd:
	cd ./src/guardian && \
		CGO_ENABLED=0 \
			go build -v \
				$(GOLANG_BUILD_FLAGS) \
				-o $(BUILD_DIR)/bin/gdn \
				./cmd/gdn

gdn-dadoo:
	cd ./src/guardian && \
		CGO_ENABLED=0 \
			go build -v \
				$(GOLANG_BUILD_FLAGS) \
				-o $(BUILD_DIR)/bin/gdn-dadoo \
				./cmd/dadoo

gdn-init:
	cd ./src/guardian/cmd/init && \
		gcc -static \
			-o $(BUILD_DIR)/bin/gdn-init \
			init.c ignore_sigchild.c


# builds the `cirocosta/golang-builder` image - the
# base image for golang-based docker images.
#
golang-builder:
	cd ./src/golang-builder && \
		docker build \
			-t cirocosta/golang-builder \
			.


# prepares a resource type directory for `registry-image`
#
registry-image-resource:
	mkdir -p $(BUILD_DIR)/resource-types/registry-image
	docker rm temp || true
	docker create --name temp \
		cirocosta/registry-image-resource
	cd $(BUILD_DIR)/resource-types/registry-image && \
		docker export temp | gzip > ./rootfs.tgz && \
		echo '{ "type": "registry-image-arm", "version": "0.0.3" }' > resource_metadata.json
	docker rm temp


registry-image-resource-image:
	cd ./src/registry-image-resource && \
		docker build \
			-t cirocosta/registry-image-resource \
			.

stop-docker:
	sudo systemctl stop docker
	sudo iptables -P INPUT ACCEPT
	sudo iptables -P FORWARD ACCEPT
	sudo iptables -P OUTPUT ACCEPT
	sudo iptables -t nat -F
	sudo iptables -t mangle -F
	sudo iptables -F
	sudo iptables -X
