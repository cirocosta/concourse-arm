GOLANG_BUILD_FLAGS = -tags netgo -ldflags '-w -extldflags "-static"'


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
rc: | fly concourse gdn resource-types
	mkdir -p linux-rc
	tar -czvf ./linux-rc/concourse.tgz -C /tmp ./concourse


resource-types: registry-image-resource



# builds fly
#
fly: 
	cd ./src/concourse/fly && \
		CGO_ENABLED=0 \
			go build -v \
			$(GOLANG_BUILD_FLAGS) \
			-o /tmp/concourse/fly-assets/fly \
			.

# builds concourse
#
concourse:
	cd ./src/concourse && \
		go build -v \
		$(GOLANG_BUILD_FLAGS) \
		-o /tmp/concourse/bin/concourse \
		./cmd/concourse
		
	
# build gdn
#
gdn: gdn-cmd gdn-init


gdn-cmd:
	cd ./src/garden-runc-release/src/guardian && \
		CGO_ENABLED=0 \
			go build -v \
				$(GOLANG_BUILD_FLAGS) \
				-o /tmp/concourse/bin/gdn \
				./cmd/gdn

gdn-init:
	echo "TODO"


golang-builder:
	cd ./src/golang-builder && \
		docker build \
			-t cirocosta/golang-builder \
			.


registry-image-resource:
	mkdir -p /tmp/concourse/resource-types/registry-image
	docker rm temp || true
	docker create --name temp \
		cirocosta/registry-image-resource
	cd /tmp/concourse/resource-types/registry-image && \
		docker export temp | gzip \
			> ./rootfs.tgz && \
		echo '{ "type": "registry-image", "version": "0.0.1" }' \
			> resource_metadata.json
	docker rm temp


# builds registry-image
#
registry-image-resource-image:
	cd ./src/registry-image-resource && \
		docker build \
			-t cirocosta/registry-image-resource \
			.
