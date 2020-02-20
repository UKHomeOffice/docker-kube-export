FROM quay.io/ukhomeofficedigital/kd:v1.18.0

RUN apk add --update --no-cache bash tar groff less python3 py-pip && \
    apk add --no-cache yq>4.0.0 --repository https://dl-cdn.alpinelinux.org/alpine/edge/community && \
    pip install awscli six

COPY bin/backup.sh /usr/local/bin/backup.sh

ENTRYPOINT ["/usr/local/bin/backup.sh"]
