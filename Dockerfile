FROM consul:0.8.3
MAINTAINER <a.kalvan@anchorfree.com>

COPY start.sh /start.sh
COPY .s3cfg /root/.s3cfg
RUN	chmod +x /start.sh && \
	chown -R consul:consul /consul && \
	apk --update --no-cache upgrade && \
	apk add --no-cache ca-certificates curl git python py-pip && \
	rm -rf /var/cache/apk/* && \
	pip install --upgrade --quiet pip python-dateutil python-magic && \
	git clone https://github.com/s3tools/s3cmd.git /opt/s3cmd && \
	ln -s /opt/s3cmd/s3cmd /bin/s3cmd

VOLUME /consul
ENTRYPOINT ["/start.sh"]
