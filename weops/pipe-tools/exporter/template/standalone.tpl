apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: haproxy-exporter
  namespace: haproxy
spec:
  serviceName: haproxy-exporter
  replicas: 1
  selector:
    matchLabels:
      app: haproxy-exporter
  template:
    metadata:
      annotations:
        telegraf.influxdata.com/interval: 1s
        telegraf.influxdata.com/inputs: |+
          [[inputs.cpu]]
            percpu = false
            totalcpu = true
            collect_cpu_time = true
            report_active = true

          [[inputs.disk]]
            ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]

          [[inputs.diskio]]

          [[inputs.kernel]]

          [[inputs.mem]]

          [[inputs.processes]]

          [[inputs.system]]
            fielddrop = ["uptime_format"]

          [[inputs.net]]
            ignore_protocol_stats = true

          [[inputs.procstat]]
            pattern = "haproxy_exporter"
        telegraf.influxdata.com/class: opentsdb
        telegraf.influxdata.com/env-fieldref-NAMESPACE: metadata.namespace
        telegraf.influxdata.com/limits-cpu: '300m'
        telegraf.influxdata.com/limits-memory: '300Mi'
      labels:
        app: haproxy-exporter
        exporter_object: haproxy
        object_mode: standalone
        pod_type: exporter
    spec:
      nodeSelector:
        node-role: worker
      shareProcessNamespace: true
      containers:
      - name: haproxy-exporter
        image: registry-svc:25000/library/haproxy-exporter:latest
        imagePullPolicy: Always
        args:
        - --haproxy.scrape-uri=http://{{HAPROXY_HOST}}:{{HAPROXY_PORT}}
        env:
        - name: HAPROXY_STATS_USER
          value: "admin"
        - name: HAPROXY_STATS_PASS
          value: "admin123"
        securityContext:
          allowPrivilegeEscalation: false
          runAsUser: 0
        resources:
          requests:
            cpu: 50m
            memory: 32Mi
          limits:
            cpu: 200m
            memory: 128Mi
        ports:
        - containerPort: 9101

---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: haproxy-exporter
  name: haproxy-exporter
  namespace: haproxy
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9101"
    prometheus.io/path: '/metrics'
spec:
  ports:
  - port: 9101
    protocol: TCP
    targetPort: 9101
  selector:
    app: haproxy-exporter
