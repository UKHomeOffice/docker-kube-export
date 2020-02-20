FROM quay.io/ukhomeofficedigital/kd:v1.15.0

RUN apk add --update --no-cache bash tar groff less python py-pip jq && \
    pip install awscli && \
    apk --purge -v del py-pip

COPY bin/backup.sh /usr/local/bin/backup.sh

ENTRYPOINT ["/usr/local/bin/backup.sh"]
