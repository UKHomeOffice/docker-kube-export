FROM quay.io/ukhomeofficedigital/kd:v1.9.6

RUN apk add --update --no-cache bash tar groff less python py-pip && \
    pip install awscli && \
    apk --purge -v del py-pip

COPY bin/backup.sh /usr/local/bin/backup.sh

ENTRYPOINT ["/usr/local/bin/backup.sh"]
