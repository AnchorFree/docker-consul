FROM consul:0.7.1
MAINTAINER <a.kalvan@anchorfree.com>

COPY start.sh /start.sh
COPY .s3cfg /root/.s3cfg
RUN chmod +x /start.sh && chown -R consul:consul /consul

RUN apk --update --no-cache upgrade && apk add --no-cache ca-certificates curl git python py-pip
RUN pip install --upgrade --quiet pip python-dateutil python-magic
RUN git clone https://github.com/s3tools/s3cmd.git /opt/s3cmd && ln -s /opt/s3cmd/s3cmd /bin/s3cmd

VOLUME /consul
ENTRYPOINT ["/start.sh"]
