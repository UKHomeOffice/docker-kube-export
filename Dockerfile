FROM quay.io/ukhomeofficedigital/kd:v1.18.0

RUN apk add --update --no-cache bash tar groff less python3 py-pip yq>4.0.0 && \
    pip install awscli six

COPY bin/backup.sh /usr/local/bin/backup.sh

ENTRYPOINT ["/usr/local/bin/backup.sh"]
