FROM consul:0.7.1
MAINTAINER <a.kalvan@anchorfree.com>

COPY start.sh /start.sh
COPY .s3cfg /root/.s3cfg

RUN chmod +x /start.sh
RUN apk update && apk upgrade && apk add --no-cache ca-certificates gnupg curl jq mc git python py-pip
RUN pip install --upgrade pip python-dateutil

RUN chown -R consul:consul /consul
RUN git clone https://github.com/s3tools/s3cmd.git /opt/s3cmd
RUN ln -s /opt/s3cmd /s3cmd

VOLUME /consul
ENTRYPOINT ["/start.sh"]
