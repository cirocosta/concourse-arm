# default flags to be used when building any go code.
#
GOLANG_BUILD_FLAGS = -tags netgo -ldflags '-w -extldflags "-static"'


# architecture to target at when building.
#
ARCH ?= arm64


# concourse version
#
VERSION ?= 5.2.0


# directory where the results of a local compilation should
# be placed.
#
BUILD_DIR ?= ./build/$(ARCH)/concourse


# builds the docker image that contains Concourse installed
# with all dependencies for running web / worker.
#
images: image-arm64 image-arm


# builds for all the supported platforms using docker
# containers and cross compilation.
#
dockerized: dockerized-arm64 dockerized-arm


image-arm64: ARCH=arm64
image-arm: ARCH=arm
image-%: dockerized-%
	docker build \
		--build-arg arch=$* \
		-t cirocosta/concourse-arm:$(VERSION)-$* \
		-f ./src/concourse-docker/Dockerfile \
		./build/$*


dockerized-arm64: ARCH=arm64
dockerized-arm: ARCH=arm
dockerized-%: binaries registry-image-resource
	tar -czvf ./build/$(ARCH)/concourse.tgz -C $(dir $(BUILD_DIR)) concourse



# builds all of the binaries needed for Concourse for a
# specific platform (`$ARCH`).
#
binaries:
	mkdir -p $(BUILD_DIR)/bin
	DOCKER_BUILDKIT=1 \
		docker build \
			--build-arg arch=$(ARCH) \
			-t binaries:$(ARCH) \
			--target binaries \
			.
	docker rm binaries-$(ARCH) || true
	docker create --name binaries-$(ARCH) binaries:$(ARCH) /bin/sh
	docker cp binaries-$(ARCH):/usr/local/concourse/bin/ $(BUILD_DIR)/


builder:
	DOCKER_BUILDKIT=1 \
		docker build \
			--build-arg arch=$(ARCH) \
			--tag cirocosta/builder-task:$(ARCH) \
			--target builder-task-image \
			.


# builds the registry-image resource type using a mix of 
# cross-platform compilation and and processor emulation.
#
registry-image-resource:
	DOCKER_BUILDKIT=1 \
		docker build \
			--build-arg arch=$(ARCH) \
			-t registry-image-resource:$(ARCH) \
			--target registry-image-resource \
			.
	mkdir -p $(BUILD_DIR)/resource-types/registry-image
	docker rm registry-image-resource-$(ARCH) || true
	docker create --name registry-image-resource-$(ARCH) \
		registry-image-resource:$(ARCH)
	cd $(BUILD_DIR)/resource-types/registry-image && \
		docker export registry-image-resource-$(ARCH) | gzip > ./rootfs.tgz && \
		echo '{ "type": "registry-image-arm", "version": "0.0.6" }' > resource_metadata.json
	docker rm registry-image-resource-$(ARCH)


clean:
	rm -rf ./build
