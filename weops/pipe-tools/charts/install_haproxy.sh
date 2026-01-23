#!/bin/bash

# HAProxy with Exporter deployment script
# Stats: http://<node-ip>:32024/stats/baz (admin/admin123)
# Exporter metrics: http://<node-ip>:32101/metrics

set -e

NAMESPACE=haproxy
RELEASE_NAME=haproxy
STATS_USER=admin
STATS_PASS=admin123

echo ">> Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# =============================================================================
# Step 1: Deploy a test nginx backend (so HAProxy has something to proxy to)
# =============================================================================
echo ">> Deploying nginx backend..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-backend
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-backend
  template:
    metadata:
      labels:
        app: nginx-backend
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 100m
            memory: 64Mi
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-backend
  namespace: $NAMESPACE
spec:
  selector:
    app: nginx-backend
  ports:
  - port: 80
    targetPort: 80
EOF

echo ">> Waiting for nginx-backend to be ready..."
kubectl rollout status deployment/nginx-backend -n $NAMESPACE --timeout=120s

# =============================================================================
# Step 2: Install HAProxy via Helm
# =============================================================================
echo ">> Installing HAProxy..."

# Check if release exists, upgrade or install accordingly
if helm status $RELEASE_NAME -n $NAMESPACE >/dev/null 2>&1; then
  HELM_CMD="helm upgrade"
else
  HELM_CMD="helm install"
fi

$HELM_CMD $RELEASE_NAME haproxytech/haproxy --namespace=$NAMESPACE \
  --set service.type=NodePort \
  --set service.nodePorts.http=32080 \
  --set service.nodePorts.https=32443 \
  --set service.nodePorts.stat=32024 \
  --set service.additionalPorts.metrics=9101 \
  --set containerPorts.stat=1024 \
  --set-string config="
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
  stats uri /stats/baz
  stats refresh 10s
  stats auth ${STATS_USER}:${STATS_PASS}

frontend fe_main
  bind *:80
  default_backend be_main

backend be_main
  server web1 nginx-backend.${NAMESPACE}.svc.cluster.local:80 check
"

echo ">> Waiting for HAProxy to be ready..."
kubectl rollout status deployment/$RELEASE_NAME -n $NAMESPACE --timeout=120s

# =============================================================================
# Step 3: Verify deployment
# =============================================================================
echo ""
echo ">> Verifying deployment..."
sleep 5

# Check backend status
echo ">> Checking HAProxy backend status..."
HAPROXY_POD=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=haproxy -o jsonpath='{.items[0].metadata.name}')
if [ -n "$HAPROXY_POD" ]; then
  kubectl exec -n $NAMESPACE $HAPROXY_POD -- wget -qO- "http://${STATS_USER}:${STATS_PASS}@127.0.0.1:1024/stats/baz?stats;csv" 2>/dev/null | grep -E "^be_main," | while read line; do
    svname=$(echo "$line" | cut -d',' -f2)
    status=$(echo "$line" | cut -d',' -f18)
    echo "   Backend: $svname -> Status: $status"
  done
fi

echo ""
echo "=============================================="
echo ">> HAProxy deployed successfully!"
echo "=============================================="
echo ">> Stats URL:    http://<node-ip>:32024/stats/baz (${STATS_USER}/${STATS_PASS})"
echo ">> Stats CSV:    http://<node-ip>:32024/stats/baz?stats;csv"
echo ">> HTTP service: http://<node-ip>:32080"
echo ""
echo ">> Exporter scrape URI should be:"
echo "   --haproxy.scrape-uri=http://${STATS_USER}:${STATS_PASS}@haproxy.${NAMESPACE}:1024/stats/baz?stats;csv"
echo ""
