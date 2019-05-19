# builds the final `cirocosta/concourse-arm` image leveraging
# the build process from previous steps, i.e., it assumes that
# the `.tgz` for the desired architecture has already been built
# and is available at `./build/`.
#


# arch - architecture that we're targetting.
#	 possible values: armhf | arm64
#
ARG arch="arm64"

FROM arm64v8/ubuntu:bionic AS ubuntu-arm64
FROM arm32v7/ubuntu:bionic AS ubuntu-armhf



FROM ubuntu-${arch} AS assets

	# release candidate .tgz produced in previous steps
	#
	COPY ./concourse.tgz /tmp
	RUN tar xzf /tmp/*tgz -C /usr/local



FROM ubuntu-${arch}

	# 'web' keys
	#
	ENV CONCOURSE_SESSION_SIGNING_KEY     /concourse-keys/session_signing_key
	ENV CONCOURSE_TSA_AUTHORIZED_KEYS     /concourse-keys/authorized_worker_keys
	ENV CONCOURSE_TSA_HOST_KEY            /concourse-keys/tsa_host_key

	# 'worker' keys
	#
	ENV CONCOURSE_TSA_PUBLIC_KEY          /concourse-keys/tsa_host_key.pub
	ENV CONCOURSE_TSA_WORKER_PRIVATE_KEY  /concourse-keys/worker_key

	# enable DNS proxy to support Docker's 127.x.x.x DNS server
	#
	ENV CONCOURSE_GARDEN_DNS_PROXY_ENABLE         true
	ENV CONCOURSE_WORKER_GARDEN_DNS_PROXY_ENABLE  true

	# auto-wire work dir for 'worker' and 'quickstart'
	#
	ENV CONCOURSE_WORK_DIR                /worker-state
	ENV CONCOURSE_WORKER_WORK_DIR         /worker-state

	# point gdn to the right place where its dependencies live
	#
	ENV CONCOURSE_GARDEN_BIN 	      /usr/local/concourse/bin/gdn
	ENV CONCOURSE_GARDEN_INIT_BIN 	      /usr/local/concourse/bin/gdn-init
	ENV CONCOURSE_GARDEN_RUNTIME_PLUGIN   /usr/local/concourse/bin/runc
	ENV CONCOURSE_GARDEN_DADOO_BIN 	      /usr/local/concourse/bin/gdn-dadoo

	# volume for non-aufs/etc. mount for baggageclaim's driver
	#
	VOLUME /worker-state

	# runtime dependencies necessary for worker + web
	#
	RUN apt update && apt install -y \
	    btrfs-tools \
	    ca-certificates \
	    dumb-init \
	    file \
	    iproute2 \
	    iptables

	COPY --from=assets /usr/local/concourse /usr/local/concourse

	ENTRYPOINT ["dumb-init", "/usr/local/concourse/bin/concourse"]
