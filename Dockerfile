FROM debian:jessie
MAINTAINER alessandro.bologna@gmail.com

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -q && apt-get install -qy --no-install-recommends \
	git build-essential libprotobuf-dev libprotobuf-c0-dev protobuf-c-compiler protobuf-compiler python-protobuf \
	libnl-3-dev libpth-dev pkg-config libcap-dev asciidoc ca-certificates iptables \
	python-pip curl \
	&& git clone https://github.com/xemul/criu \
	&& cd criu/ && make -j \
	&& cp criu/criu /usr/local/bin/criu \
	&& pip install awscli \
    && apt-get purge -y --auto-remove build-essential protobuf-c-compiler\
    	protobuf-compiler python-protobuf \
		pkg-config asciidoc \
    && rm -rf /var/lib/apt/lists/*  /tmp/*

COPY freezer /usr/local/bin
RUN chmod +x /usr/local/bin/freezer
VOLUME ["/dump"]
CMD ["start"]
ENTRYPOINT ["/usr/local/bin/freezer"]