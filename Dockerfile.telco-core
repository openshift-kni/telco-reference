FROM registry.access.redhat.com/ubi9/ubi-minimal

COPY ./telco-core /usr/share/telco-core-rds

RUN microdnf install -y tar && \
    microdnf clean -y all

USER 65532:65532
ENTRYPOINT ["/bin/bash"]
CMD ["-c", "tar -cf - --directory /usr/share telco-core-rds | base64 -w0"]
