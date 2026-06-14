# Vinyl Radar Backend (V1)

纯 Python 标准库实现的聚合服务，提供：
- `GET /v1/radar/releases`
- `GET /v1/radar/refresh-status`
- `POST /admin/refresh`
- `GET /health`

## 已接入信息源（V1）
- Blood Records
- bad world
- Banquet Records

`Rough Trade US` 已预留适配器骨架，未加入运行管线。

## 快速启动
在仓库根目录执行：

```bash
python3 -m backend.app
```

默认监听：`127.0.0.1:8080`

仅执行一次刷新（不启动 HTTP 端口）：

```bash
python3 -m backend.app --once
```

### 可选环境变量
- `RADAR_BACKEND_HOST`：默认 `127.0.0.1`
- `RADAR_BACKEND_PORT`：默认 `8080`
- `RADAR_REFRESH_INTERVAL_SECONDS`：默认 `600`（10 分钟）

## 与 iOS 对接
在 Xcode 的 Scheme Environment Variables 设置：

- `RADAR_API_BASE_URL=http://127.0.0.1:8080`

App 会请求：

- `GET /v1/radar/releases`

返回 `releases[]` 关键字段：
- `id, artist, title, storeID, publishedAt, flags`
- `coverImageURL`（可空）
- `sourceItemURL`（可空）
- `sourceItemKey`
- `description`（可空，短描述）
- `isSoldOut`（是否已售罄）

顶层附带 `refreshMeta`：
- `generatedAt`
- `perSource`
- `failedSources`
- `warnings`

## 数据持久化
运行时文件写入：
- `backend/data/snapshot.json`
- `backend/data/state.json`

说明：
- `snapshot.json`：最新聚合结果
- `state.json`：`first_seen`（用于 `NEW` 72 小时规则）

## 标记规则
- `NEW`：first seen <= 72h
- `LIMITED`：`limited/copies/numbered`
- `COLORED`：`colored/coloured/splatter/clear/marble`
- `EXCLUSIVE`：`exclusive/store exclusive`

## 注意
当前 HTML 解析为无依赖启发式方案（优先“可运行 + 可扩展”），站点改版后请按 adapter 定点调整。
