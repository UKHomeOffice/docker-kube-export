FROM alpine:3.6
ENV KUBECTL_VERSION v1.8.3
RUN apk add --update --no-cache bash curl tar

RUN curl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
  -o /usr/bin/kubectl && chmod +x /usr/bin/kubectl

RUN apk -Uuv add --no-cache groff less python py-pip && \
    pip install awscli && \
    apk --purge -v del py-pip

ADD bin/* /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/backup.sh"]
