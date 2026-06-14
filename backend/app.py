from __future__ import annotations

import json
import logging
import os
import threading
import argparse
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Optional
from urllib.parse import parse_qs, urlparse

from .aggregator import FeedAggregator
from .models import to_iso8601, utc_now
from .storage import JsonStore


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s - %(message)s",
)
logger = logging.getLogger("vinyl_radar_backend")


def env_int(name: str, default: int) -> int:
    raw = os.getenv(name)
    if not raw:
        return default
    try:
        return int(raw)
    except ValueError:
        return default


class RefreshScheduler(threading.Thread):
    def __init__(self, aggregator: FeedAggregator, interval_seconds: int) -> None:
        super().__init__(daemon=True)
        self._aggregator = aggregator
        self._interval_seconds = interval_seconds
        self._stop = threading.Event()

    def run(self) -> None:
        while not self._stop.is_set():
            try:
                metrics = self._aggregator.refresh()
                logger.info(
                    "refresh complete total=%d per_source=%s failed_sources=%s warnings=%s",
                    metrics.total,
                    metrics.per_source,
                    metrics.failed_sources,
                    metrics.warnings,
                )
            except Exception as exc:  # noqa: BLE001
                logger.exception("refresh loop failed: %s", exc)
            self._stop.wait(self._interval_seconds)

    def stop(self) -> None:
        self._stop.set()


class RadarHandler(BaseHTTPRequestHandler):
    server_version = "VinylRadarBackend/0.1"

    @property
    def aggregator(self) -> FeedAggregator:
        return self.server.aggregator  # type: ignore[attr-defined]

    def do_GET(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)

        if parsed.path == "/health":
            self._write_json(
                HTTPStatus.OK,
                {
                    "ok": True,
                    "service": "vinyl-radar-backend",
                    "now": to_iso8601(utc_now()),
                },
            )
            return

        if parsed.path == "/v1/radar/releases":
            query = parse_qs(parsed.query)
            if query.get("refresh", ["0"])[0] == "1":
                self.aggregator.refresh()
            snapshot = self.aggregator.get_snapshot()
            self._write_json(HTTPStatus.OK, snapshot)
            return

        if parsed.path == "/v1/radar/refresh-status":
            status = self.aggregator.get_refresh_status()
            self._write_json(HTTPStatus.OK, status)
            return

        self._write_json(HTTPStatus.NOT_FOUND, {"error": "Not Found"})

    def do_POST(self) -> None:  # noqa: N802
        if self.path == "/admin/refresh":
            metrics = self.aggregator.refresh()
            self._write_json(
                HTTPStatus.OK,
                {
                    "ok": True,
                    "generatedAt": metrics.generated_at,
                    "total": metrics.total,
                    "perSource": metrics.per_source,
                    "failedSources": metrics.failed_sources,
                    "warnings": metrics.warnings,
                },
            )
            return

        self._write_json(HTTPStatus.NOT_FOUND, {"error": "Not Found"})

    def log_message(self, format: str, *args) -> None:  # noqa: A003
        logger.info("%s - %s", self.client_address[0], format % args)

    def _write_json(self, status: HTTPStatus, payload: dict) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status.value)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def create_server(host: str, port: int, data_dir: Optional[Path] = None) -> tuple[ThreadingHTTPServer, RefreshScheduler]:
    root = data_dir or Path(__file__).resolve().parent / "data"
    store = JsonStore(root)
    aggregator = FeedAggregator(store=store)

    server = ThreadingHTTPServer((host, port), RadarHandler)
    server.aggregator = aggregator  # type: ignore[attr-defined]

    interval_seconds = env_int("RADAR_REFRESH_INTERVAL_SECONDS", 600)
    scheduler = RefreshScheduler(aggregator=aggregator, interval_seconds=interval_seconds)
    return server, scheduler


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Vinyl Radar backend service")
    parser.add_argument(
        "--once",
        action="store_true",
        help="Run a single refresh cycle and exit (no HTTP server).",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    host = os.getenv("RADAR_BACKEND_HOST", "127.0.0.1")
    port = env_int("RADAR_BACKEND_PORT", 8080)
    data_dir = Path(__file__).resolve().parent / "data"
    route_table = ["/health", "/v1/radar/releases", "/v1/radar/refresh-status", "/admin/refresh"]

    logger.info(
        "runtime self-check module=%s cwd=%s routes=%s",
        Path(__file__).resolve(),
        Path.cwd(),
        route_table,
    )

    if args.once:
        store = JsonStore(data_dir)
        aggregator = FeedAggregator(store=store)
        metrics = aggregator.refresh()
        logger.info(
            "one-shot refresh complete total=%d per_source=%s failed_sources=%s warnings=%s",
            metrics.total,
            metrics.per_source,
            metrics.failed_sources,
            metrics.warnings,
        )
        return

    server, scheduler = create_server(host=host, port=port, data_dir=data_dir)
    logger.info("starting backend host=%s port=%d", host, port)

    scheduler.start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("shutdown requested")
    finally:
        scheduler.stop()
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    main()
