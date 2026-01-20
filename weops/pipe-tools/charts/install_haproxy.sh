#!/bin/bash

# HAProxy with Exporter deployment script
# Stats: http://<node-ip>:32024/stats (admin/admin123)
# Exporter metrics: http://<node-ip>:32101/metrics

NAMESPACE=haproxy
RELEASE_NAME=haproxy
STATS_USER=admin
STATS_PASS=admin123

# Add helm repo
#helm repo add haproxytech https://haproxytech.github.io/helm-charts
#helm repo update

# Create namespace if not exists
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Install HAProxy with exporter sidecar
helm install $RELEASE_NAME haproxytech/haproxy --namespace=$NAMESPACE \
  --set service.type=NodePort \
  --set service.nodePorts.http=32080 \
  --set service.nodePorts.https=32443 \
  --set service.nodePorts.stat=32024 \
  --set service.additionalPorts.metrics=9101 \
  --set containerPorts.stat=1024 \
  --set config="
# =============================================================================
# HAProxy Configuration
# =============================================================================
# global:         Global process settings (logging, max connections)
# defaults:       Default settings applied to all frontends/backends
# frontend stats: Stats page on port 1024 with basic auth (for exporter scraping)
# frontend fe_main: Main HTTP listener on port 80
# backend be_main:  Backend servers (modify server list for your environment)
# =============================================================================
global
  log stdout format raw local0
  maxconn 1024

defaults
  log global
  mode http
  option httplog
  timeout client 60s
  timeout connect 60s
  timeout server 60s

frontend stats
  bind *:1024
  stats enable
  stats uri /stats
  stats refresh 10s
  stats auth ${STATS_USER}:${STATS_PASS}

frontend fe_main
  bind *:80
  default_backend be_main

backend be_main
  server web1 127.0.0.1:8080 check
"


echo ""
echo ">> HAProxy with Exporter deployed!"
echo ">> Stats URL: http://<node-ip>:32024/stats (${STATS_USER}/${STATS_PASS})"
echo ">> HTTP service: http://<node-ip>:32080"
