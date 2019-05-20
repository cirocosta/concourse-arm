#!/bin/bash

set -o errexit
set -o xtrace

main() {
	setup_resource
	setup_binaries
	pack_it_all
}

setup_resource() {
	mkdir -p concourse/resource-types/registry-image-resource/

	tar -czf \
		concourse/resource-types/registry-image-resource/rootfs.tgz \
		-C ./registry-image-resource/rootfs .

	echo '{
	"type": "registry-image-arm", 
	"version": "0.0.6"
}' >concourse/resource-types/registry-image-resource/resource_metadata.json
}

setup_binaries() {
	mkdir -p concourse/bin
	mv ./binaries/rootfs/usr/local/concourse/bin/* concourse/bin/
}

pack_it_all () {
	tar -czvf ./rc/concourse.tgz ./concourse
}

main
