FROM alpine:3.6

RUN apk -v --update add \
		ca-certificates \
        python \
        py-pip \
        groff \
        less \
        mailcap \
		openssl \
		curl \
        && \
    pip install --upgrade awscli==1.16.43 python-magic && \
	update-ca-certificates && \
    apk -v --purge del py-pip

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.12.2/bin/linux/amd64/kubectl \
	&& chmod +x kubectl \
	&& mv kubectl /usr/local/bin

ADD update_creds.sh /

CMD ["/update_creds.sh"]
