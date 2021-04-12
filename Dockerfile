FROM quay.io/ukhomeofficedigital/kd:v1.18.0

RUN apk add --update --no-cache bash tar groff less python3 py-pip jq && \
    pip install awscli six yq

COPY bin/backup.sh /usr/local/bin/backup.sh

ENTRYPOINT ["/usr/local/bin/backup.sh"]
