from __future__ import annotations

import json
import threading
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional

from .models import Release, parse_iso8601, to_iso8601


@dataclass
class FeedState:
    first_seen: Dict[str, str]


class JsonStore:
    def __init__(self, root: Path) -> None:
        self._root = root
        self._root.mkdir(parents=True, exist_ok=True)
        self._snapshot_path = root / "snapshot.json"
        self._state_path = root / "state.json"
        self._lock = threading.Lock()

    def load_snapshot(self) -> Optional[dict]:
        with self._lock:
            if not self._snapshot_path.exists():
                return None
            return json.loads(self._snapshot_path.read_text(encoding="utf-8"))

    def save_snapshot(
        self,
        generated_at: str,
        releases: List[Release],
        refresh_meta: Optional[Dict[str, Any]] = None,
    ) -> None:
        payload = {
            "generatedAt": generated_at,
            "releases": [release.to_dict() for release in releases],
        }
        if refresh_meta is not None:
            payload["refreshMeta"] = refresh_meta
        with self._lock:
            self._snapshot_path.write_text(
                json.dumps(payload, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )

    def load_refresh_meta(self) -> Dict[str, Any]:
        snapshot = self.load_snapshot()
        if not snapshot:
            return {
                "generatedAt": None,
                "perSource": {},
                "failedSources": {},
                "warnings": [],
            }
        return dict(snapshot.get("refreshMeta", {}))

    def load_state(self) -> FeedState:
        with self._lock:
            if not self._state_path.exists():
                return FeedState(first_seen={})
            data = json.loads(self._state_path.read_text(encoding="utf-8"))
            return FeedState(first_seen=dict(data.get("first_seen", {})))

    def save_state(self, state: FeedState) -> None:
        payload = {"first_seen": state.first_seen}
        with self._lock:
            self._state_path.write_text(
                json.dumps(payload, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )


def state_key(store_id: str, source_item_key: str) -> str:
    return f"{store_id}::{source_item_key}"


def resolve_first_seen(state: FeedState, store_id: str, source_item_key: str, now_iso: str) -> str:
    key = state_key(store_id, source_item_key)
    existing = state.first_seen.get(key)
    if existing:
        return existing
    state.first_seen[key] = now_iso
    return now_iso


def load_releases_from_snapshot(snapshot: Optional[dict]) -> List[Release]:
    if not snapshot:
        return []
    return [Release.from_dict(item) for item in snapshot.get("releases", [])]


def parse_first_seen(value: str):
    return parse_iso8601(value)


def format_first_seen(dt):
    return to_iso8601(dt)
