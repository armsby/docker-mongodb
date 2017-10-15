FROM arm64v8/ubuntu


RUN groupadd -r mongodb && useradd -r -g mongodb mongodb

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		jq \
		numactl \
	&& rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends wget && rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
	&& apt-get purge -y --auto-remove wget

RUN mkdir /docker-entrypoint-initdb.d

#ENV GPG_KEYS \
## pub   4096R/91FA4AD5 2016-12-14 [expires: 2018-12-14]
##       Key fingerprint = 2930 ADAE 8CAF 5059 EE73  BB4B 5871 2A22 91FA 4AD5
## uid                  MongoDB 3.6 Release Signing Key <packaging@mongodb.com>
#	2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5
## https://docs.mongodb.com/manual/tutorial/verify-mongodb-packages/#download-then-import-the-key-file
#RUN set -ex; \
#	export GNUPGHOME="$(mktemp -d)"; \
#	for key in $GPG_KEYS; do \
#		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
#	done; \
#	gpg --export $GPG_KEYS > /etc/apt/trusted.gpg.d/mongodb.gpg; \
#	rm -r "$GNUPGHOME"; \
#	apt-key list

RUN set -x \
	&& apt-get update \
	&& apt-get install -y mongodb \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mongodb

RUN mkdir -p /data/db /data/configdb \
	&& chown -R mongodb:mongodb /data/db /data/configdb
VOLUME /data/db /data/configdb

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

EXPOSE 27017
CMD ["mongod"]
