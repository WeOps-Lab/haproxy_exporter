#
# build container
#
FROM --platform=linux/amd64 golang:1.19-alpine as builder
WORKDIR /

COPY haproxy_exporter_linux_amd64 /haproxy_exporter_linux_amd64

EXPOSE     9101
ENTRYPOINT ["/haproxy_exporter_linux_amd64"]
