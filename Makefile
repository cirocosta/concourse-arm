# default flags to be used when building any go code.
#
GOLANG_BUILD_FLAGS = -tags netgo -ldflags '-w -extldflags "-static"'


# architecture to target at when building.
#
ARCH ?= arm64


# directory where the results of a local compilation should
# be placed.
#
BUILD_DIR ?= ./build/$(ARCH)/concourse



# builds for all the supported platforms using docker
# containers and cross compilation.
#
dockerized: dockerized-arm64 dockerized-armhf final-image


final-image-arm64: ARCH=arm64
final-image-armhf: ARCH=armhf
dockerized-arm64: ARCH=arm64
dockerized-armhf: ARCH=armhf

final-image-%:
	docker build \
		-t cirocosta/concourse-arm:$* \
		-f ./src/concourse-docker/Dockerfile \
		./build/$*

dockerized-%: dockerized-binaries dockerized-registry-image-resource
	tar -czvf ./build/$(ARCH)/concourse.tgz -C $(dir $(BUILD_DIR)) concourse



# builds all of the binaries needed for Concourse for a
# specific platform (`$ARCH`).
#
dockerized-binaries:
	mkdir -p $(BUILD_DIR)/bin
	DOCKER_BUILDKIT=1 \
		docker build -t binaries --target binaries .
	docker rm binaries || true
	docker create --name binaries binaries /bin/sh
	docker cp binaries:/usr/local/concourse/bin/ $(BUILD_DIR)/


# builds the registry-image resource type using a mix of 
# cross-platform compilation and and processor emulation.
#
dockerized-registry-image-resource:
	DOCKER_BUILDKIT=1 \
		docker build -t registry-image-resource --target registry-image-resource .
	mkdir -p $(BUILD_DIR)/resource-types/registry-image
	docker rm temp || true
	docker create --name temp \
		registry-image-resource
	cd $(BUILD_DIR)/resource-types/registry-image && \
		docker export temp | gzip > ./rootfs.tgz && \
		echo '{ "type": "registry-image-arm", "version": "0.0.6" }' > resource_metadata.json
	docker rm temp


clean:
	rm -rf ./build
