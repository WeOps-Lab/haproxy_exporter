## 嘉为蓝鲸HAProxy插件使用说明

## 使用说明

### 插件功能

采集器连接HAProxy统计接口，抓取HAProxy的统计数据，将结果解析为Prometheus数据格式的监控指标。

### 版本支持

操作系统支持: linux, windows

是否支持arm: 支持

**组件支持版本：**

HAProxy: >= `1.5`

**是否支持远程采集:**

是

### 参数说明

| **参数名**                         | **类型** | **含义**                               | **是否必填** | **默认值** | **使用举例**                                  |
|---------------------------------|--------|--------------------------------------|----------|---------|-------------------------------------------|
| --haproxy.scrape-uri            | 参数     | HAProxy统计接口URI                       | 是        | -       | http://127.0.0.1:1024/stats/baz?stats;csv |
| HAPROXY_STATS_USER              | 环境变量   | HAProxy统计接口用户名                       | 否        | -       | admin                                     |
| HAPROXY_STATS_PASS              | 环境变量   | HAProxy统计接口密码(特殊字符不需要转义)             | 否        | -       | admin123                                  |
| --no-haproxy.ssl-verify         | 参数     | 禁用HTTPS证书验证（开关参数）                    | 否        | -       |                                           |
| --haproxy.server-exclude-states | 参数     | 要排除的server状态，逗号分隔（如MAINT维护状态的服务器不采集） | 否        | -       | MAINT                                     |
| --haproxy.timeout               | 参数     | 抓取HAProxy统计数据的超时时间                   | 否        | 5s      | 10s                                       |
| --web.listen-address            | 参数     | exporter监听地址及端口                      | 否        | :9101   | 0.0.0.0:9101                              |

### 使用指引

1. 在HAProxy中启用统计页面

   在 `haproxy.cfg` 中添加stats frontend配置：

   ```haproxy
   frontend stats
     bind *:1024
     stats enable
     stats uri /stats/baz
     stats refresh 10s
     stats auth admin:admin123
   ```

   配置项说明：

   | 配置项                         | 说明                                   |
   |-----------------------------|--------------------------------------|
   | `bind *:1024`               | 统计页面监听端口，`*`表示监听所有网卡，`1024`为端口号      |
   | `stats enable`              | 启用统计页面功能                             |
   | `stats uri /stats/baz`      | 统计页面访问路径，exporter的scrape-uri需要与此路径一致 |
   | `stats refresh 10s`         | 页面自动刷新间隔（仅影响Web页面，不影响exporter采集）     |
   | `stats auth admin:admin123` | 访问认证，格式为`用户名:密码`，exporter需使用相同的认证信息  |

2. 验证统计接口可用

   ```bash
   curl -u admin:admin123 "http://localhost:1024/stats/baz?stats;csv"
   ```

   应返回CSV格式的统计数据，包含frontend、backend、server的统计信息。

3. 常见问题排查

   | 现象                     | 可能原因            | 解决方案                                |
   |------------------------|-----------------|-------------------------------------|
   | `haproxy_up 0`         | 无法连接HAProxy统计接口 | 检查scrape-uri地址、端口、认证信息是否正确          |
   | `haproxy_server_up 0`  | 后端服务器健康检查失败     | 检查HAProxy后端服务器是否正常运行                |
   | `haproxy_backend_up 0` | 后端所有服务器都不可用     | 检查backend中的server配置及健康状态            |
   | 连接被拒绝                  | 统计端口未监听或防火墙阻止   | 检查HAProxy配置中的bind端口及防火墙规则           |
   | 401 Unauthorized       | 认证信息错误          | 检查stats auth配置与exporter使用的用户名密码是否一致 |

### 指标简介
| **指标ID**                                           | **指标中文名**     | **维度ID**              | **维度含义**             | **单位** | **指标类型** |
|----------------------------------------------------|---------------|-----------------------|----------------------|--------|----------|
| haproxy_up                                         | 监控插件运行状态      | -                     | -                    | -      | gauge    |
| haproxy_backend_up                                 | 后端健康状态        | backend               | 后端名称                 | -      | gauge    |
| haproxy_server_up                                  | 服务器健康状态       | server, backend       | 服务器名称, 后端名称          | -      | gauge    |
| haproxy_frontend_bytes_in_total                    | 前端接收字节数       | frontend              | 前端名称                 | bytes  | counter  |
| haproxy_frontend_bytes_out_total                   | 前端发送字节数       | frontend              | 前端名称                 | bytes  | counter  |
| haproxy_frontend_compressor_bytes_bypassed_total   | 前端绕过压缩字节数     | frontend              | 前端名称                 | bytes  | counter  |
| haproxy_frontend_compressor_bytes_in_total         | 前端压缩器输入字节数    | frontend              | 前端名称                 | bytes  | counter  |
| haproxy_frontend_compressor_bytes_out_total        | 前端压缩器输出字节数    | frontend              | 前端名称                 | bytes  | counter  |
| haproxy_frontend_connections_total                 | 前端连接总数        | frontend              | 前端名称                 | -      | counter  |
| haproxy_frontend_current_session_rate              | 前端当前会话速率      | frontend              | 前端名称                 | qps    | gauge    |
| haproxy_frontend_current_sessions                  | 前端当前活跃会话数     | frontend              | 前端名称                 | -      | gauge    |
| haproxy_frontend_http_requests_total               | 前端HTTP请求总数    | frontend              | 前端名称                 | -      | counter  |
| haproxy_frontend_http_responses_compressed_total   | 前端已压缩HTTP响应数  | frontend              | 前端名称                 | -      | counter  |
| haproxy_frontend_http_responses_total              | 前端HTTP响应总数    | code, frontend        | HTTP状态码, 前端名称        | -      | counter  |
| haproxy_frontend_limit_session_rate                | 前端会话速率限制      | frontend              | 前端名称                 | qps    | gauge    |
| haproxy_frontend_limit_sessions                    | 前端会话限制数       | frontend              | 前端名称                 | -      | gauge    |
| haproxy_frontend_max_session_rate                  | 前端最大会话速率      | frontend              | 前端名称                 | qps    | gauge    |
| haproxy_frontend_max_sessions                      | 前端最大活跃会话数     | frontend              | 前端名称                 | -      | gauge    |
| haproxy_frontend_request_errors_total              | 前端请求错误数       | frontend              | 前端名称                 | -      | counter  |
| haproxy_frontend_requests_denied_total             | 前端拒绝请求数       | frontend              | 前端名称                 | -      | counter  |
| haproxy_frontend_sessions_total                    | 前端会话总数        | frontend              | 前端名称                 | -      | counter  |
| haproxy_backend_bytes_in_total                     | 后端接收字节数       | backend               | 后端名称                 | bytes  | counter  |
| haproxy_backend_bytes_out_total                    | 后端发送字节数       | backend               | 后端名称                 | bytes  | counter  |
| haproxy_backend_client_aborts_total                | 后端客户端中止传输数    | backend               | 后端名称                 | -      | counter  |
| haproxy_backend_compressor_bytes_bypassed_total    | 后端绕过压缩字节数     | backend               | 后端名称                 | bytes  | counter  |
| haproxy_backend_compressor_bytes_in_total          | 后端压缩器输入字节数    | backend               | 后端名称                 | bytes  | counter  |
| haproxy_backend_compressor_bytes_out_total         | 后端压缩器输出字节数    | backend               | 后端名称                 | bytes  | counter  |
| haproxy_backend_connection_errors_total            | 后端连接错误数       | backend               | 后端名称                 | -      | counter  |
| haproxy_backend_current_queue                      | 后端当前排队请求数     | backend               | 后端名称                 | -      | gauge    |
| haproxy_backend_current_server                     | 后端活跃服务器数      | backend               | 后端名称                 | -      | gauge    |
| haproxy_backend_current_session_rate               | 后端当前会话速率      | backend               | 后端名称                 | qps    | gauge    |
| haproxy_backend_current_sessions                   | 后端当前活跃会话数     | backend               | 后端名称                 | -      | gauge    |
| haproxy_backend_http_connect_time_average_seconds  | 后端HTTP平均连接时间  | backend               | 后端名称                 | s      | gauge    |
| haproxy_backend_http_queue_time_average_seconds    | 后端HTTP平均排队时间  | backend               | 后端名称                 | s      | gauge    |
| haproxy_backend_http_response_time_average_seconds | 后端HTTP平均响应时间  | backend               | 后端名称                 | s      | gauge    |
| haproxy_backend_http_responses_compressed_total    | 后端已压缩HTTP响应数  | backend               | 后端名称                 | -      | counter  |
| haproxy_backend_http_responses_total               | 后端HTTP响应总数    | backend, code         | 后端名称, HTTP状态码        | -      | counter  |
| haproxy_backend_http_total_time_average_seconds    | 后端HTTP平均总时间   | backend               | 后端名称                 | s      | gauge    |
| haproxy_backend_limit_sessions                     | 后端会话限制数       | backend               | 后端名称                 | -      | gauge    |
| haproxy_backend_max_queue                          | 后端最大排队请求数     | backend               | 后端名称                 | -      | gauge    |
| haproxy_backend_max_session_rate                   | 后端最大会话速率      | backend               | 后端名称                 | qps    | gauge    |
| haproxy_backend_max_sessions                       | 后端最大活跃会话数     | backend               | 后端名称                 | -      | gauge    |
| haproxy_backend_redispatch_warnings_total          | 后端重调度警告数      | backend               | 后端名称                 | -      | counter  |
| haproxy_backend_response_errors_total              | 后端响应错误数       | backend               | 后端名称                 | -      | counter  |
| haproxy_backend_retry_warnings_total               | 后端重试警告数       | backend               | 后端名称                 | -      | counter  |
| haproxy_backend_server_aborts_total                | 后端服务器中止传输数    | backend               | 后端名称                 | -      | counter  |
| haproxy_backend_server_selected_total              | 后端服务器被选中次数    | backend               | 后端名称                 | -      | counter  |
| haproxy_backend_sessions_total                     | 后端会话总数        | backend               | 后端名称                 | -      | counter  |
| haproxy_backend_weight                             | 后端服务器总权重      | backend               | 后端名称                 | -      | gauge    |
| haproxy_server_bytes_in_total                      | 服务器接收字节数      | server, backend       | 服务器名称, 后端名称          | bytes  | counter  |
| haproxy_server_bytes_out_total                     | 服务器发送字节数      | server, backend       | 服务器名称, 后端名称          | bytes  | counter  |
| haproxy_server_check_duration_seconds              | 服务器健康检查耗时     | server, backend       | 服务器名称, 后端名称          | s      | gauge    |
| haproxy_server_check_failures_total                | 服务器健康检查失败数    | server, backend       | 服务器名称, 后端名称          | -      | counter  |
| haproxy_server_client_aborts_total                 | 服务器客户端中止传输数   | server, backend       | 服务器名称, 后端名称          | -      | counter  |
| haproxy_server_connection_errors_total             | 服务器连接错误数      | server, backend       | 服务器名称, 后端名称          | -      | counter  |
| haproxy_server_current_queue                       | 服务器当前排队请求数    | server, backend       | 服务器名称, 后端名称          | -      | gauge    |
| haproxy_server_current_session_rate                | 服务器当前会话速率     | server, backend       | 服务器名称, 后端名称          | qps    | gauge    |
| haproxy_server_current_sessions                    | 服务器当前活跃会话数    | server, backend       | 服务器名称, 后端名称          | -      | gauge    |
| haproxy_server_downtime_seconds_total              | 服务器宕机时长       | server, backend       | 服务器名称, 后端名称          | s      | counter  |
| haproxy_server_http_connect_time_average_seconds   | 服务器HTTP平均连接时间 | server, backend       | 服务器名称, 后端名称          | s      | gauge    |
| haproxy_server_http_queue_time_average_seconds     | 服务器HTTP平均排队时间 | server, backend       | 服务器名称, 后端名称          | s      | gauge    |
| haproxy_server_http_response_time_average_seconds  | 服务器HTTP平均响应时间 | server, backend       | 服务器名称, 后端名称          | s      | gauge    |
| haproxy_server_http_responses_total                | 服务器HTTP响应总数   | server, backend, code | 服务器名称, 后端名称, HTTP状态码 | -      | counter  |
| haproxy_server_http_total_time_average_seconds     | 服务器HTTP平均总时间  | server, backend       | 服务器名称, 后端名称          | s      | gauge    |
| haproxy_server_max_queue                           | 服务器最大排队请求数    | server, backend       | 服务器名称, 后端名称          | -      | gauge    |
| haproxy_server_max_session_rate                    | 服务器最大会话速率     | server, backend       | 服务器名称, 后端名称          | qps    | gauge    |
| haproxy_server_max_sessions                        | 服务器最大活跃会话数    | server, backend       | 服务器名称, 后端名称          | -      | gauge    |
| haproxy_server_redispatch_warnings_total           | 服务器重调度警告数     | server, backend       | 服务器名称, 后端名称          | -      | counter  |
| haproxy_server_response_errors_total               | 服务器响应错误数      | server, backend       | 服务器名称, 后端名称          | -      | counter  |
| haproxy_server_retry_warnings_total                | 服务器重试警告数      | server, backend       | 服务器名称, 后端名称          | -      | counter  |
| haproxy_server_server_aborts_total                 | 服务器中止传输数      | server, backend       | 服务器名称, 后端名称          | -      | counter  |
| haproxy_server_server_selected_total               | 服务器被选中次数      | server, backend       | 服务器名称, 后端名称          | -      | counter  |
| haproxy_server_sessions_total                      | 服务器会话总数       | server, backend       | 服务器名称, 后端名称          | -      | counter  |
| haproxy_server_weight                              | 服务器当前权重       | server, backend       | 服务器名称, 后端名称          | -      | gauge    |
| haproxy_exporter_csv_parse_failures_total          | 监控探针CSV解析失败次数 | -                     | -                    | -      | counter  |
| haproxy_exporter_scrapes_total                     | 监控探针抓取总次数     | -                     | -                    | -      | counter  |


### 版本日志

#### haproxy_exporter v0.15.0
- weops调整

