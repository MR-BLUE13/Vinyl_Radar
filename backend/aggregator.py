from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime
from typing import Dict, Iterable, List, Sequence

from .adapters.bad_world import BadWorldAdapter
from .adapters.banquet_records import BanquetRecordsAdapter
from .adapters.base import SourceAdapter
from .adapters.blood_records import BloodRecordsAdapter
from .dedupe import dedupe_within_store
from .flags import classify_flags
from .models import Release, RawRelease, build_release_id, to_iso8601, utc_now
from .storage import FeedState, JsonStore, load_releases_from_snapshot, parse_first_seen, resolve_first_seen

logger = logging.getLogger(__name__)


@dataclass
class RefreshMetrics:
    generated_at: str
    total: int
    per_source: Dict[str, int]
    failed_sources: Dict[str, str]


class FeedAggregator:
    def __init__(self, store: JsonStore, adapters: Sequence[SourceAdapter] | None = None) -> None:
        self.store = store
        self.adapters = list(adapters) if adapters else [
            BloodRecordsAdapter(),
            BadWorldAdapter(),
            BanquetRecordsAdapter(),
        ]

    def get_snapshot(self) -> dict:
        snapshot = self.store.load_snapshot()
        if snapshot:
            return snapshot

        self.refresh()
        snapshot = self.store.load_snapshot()
        return snapshot or {"generatedAt": to_iso8601(utc_now()), "releases": []}

    def refresh(self) -> RefreshMetrics:
        now = utc_now()
        state = self.store.load_state()
        existing_snapshot = self.store.load_snapshot()
        existing_by_store = _group_by_store(load_releases_from_snapshot(existing_snapshot))

        normalized: List[Release] = []
        per_source: Dict[str, int] = {}
        failed_sources: Dict[str, str] = {}

        for adapter in self.adapters:
            source = adapter.source
            try:
                raws = adapter.fetch_latest(now)
                converted = [self._normalize(raw, state, now) for raw in raws]
                normalized.extend(converted)
                per_source[source] = len(converted)
                logger.info("source=%s fetched=%d", source, len(converted))
            except Exception as exc:  # noqa: BLE001
                failed_sources[source] = str(exc)
                fallback = existing_by_store.get(adapter.store_id, [])
                normalized.extend(fallback)
                per_source[source] = len(fallback)
                logger.warning("source=%s failed=%s fallback=%d", source, exc, len(fallback))

        merged = dedupe_within_store(normalized)
        generated_at = to_iso8601(now)

        self.store.save_state(state)
        self.store.save_snapshot(generated_at, merged)

        return RefreshMetrics(
            generated_at=generated_at,
            total=len(merged),
            per_source=per_source,
            failed_sources=failed_sources,
        )

    def _normalize(self, raw: RawRelease, state: FeedState, now: datetime) -> Release:
        now_iso = to_iso8601(now)
        first_seen_iso = resolve_first_seen(state, raw.store_id, raw.source_item_key, now_iso)
        first_seen_at = parse_first_seen(first_seen_iso)

        text_for_flags = " ".join(part for part in [raw.artist, raw.title, raw.subtitle] if part)
        flags = classify_flags(text_for_flags, first_seen_at=first_seen_at, now=now)

        published_at = raw.published_at or now
        release_id = build_release_id(raw.source, raw.source_item_key)

        return Release(
            id=release_id,
            artist=raw.artist,
            title=raw.title,
            coverImageURL=raw.cover_image_url,
            sourceItemURL=raw.source_item_url,
            sourceItemKey=raw.source_item_key,
            storeID=raw.store_id,
            publishedAt=published_at,
            flags=flags,
        )


def _group_by_store(releases: Iterable[Release]) -> Dict[str, List[Release]]:
    grouped: Dict[str, List[Release]] = {}
    for release in releases:
        grouped.setdefault(release.storeID, []).append(release)
    return grouped
