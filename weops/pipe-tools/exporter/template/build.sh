#!/bin/bash

HAPROXY_HOST="${HAPROXY_HOST:-haproxy.haproxy}"
HAPROXY_PORT="${HAPROXY_PORT:-1024}"


output_file="standalone.yaml"
sed "s/{{HAPROXY_HOST}}/${HAPROXY_HOST}/g; s/{{HAPROXY_PORT}}/${HAPROXY_PORT}/g" standalone.tpl > ../standalone/${output_file}

