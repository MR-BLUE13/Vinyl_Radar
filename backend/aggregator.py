from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Dict, Iterable, List, Sequence

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
    warnings: List[str]


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
        if snapshot:
            return snapshot
        empty_generated_at = to_iso8601(utc_now())
        return {
            "generatedAt": empty_generated_at,
            "releases": [],
            "refreshMeta": _build_refresh_meta(
                generated_at=empty_generated_at,
                per_source={},
                failed_sources={},
                warnings=[],
            ),
        }

    def get_refresh_status(self) -> dict:
        snapshot = self.store.load_snapshot()
        if snapshot and snapshot.get("refreshMeta"):
            return snapshot["refreshMeta"]
        return {
            "generatedAt": to_iso8601(utc_now()),
            "perSource": {},
            "failedSources": {},
            "warnings": [],
        }

    def refresh(self) -> RefreshMetrics:
        now = utc_now()
        state = self.store.load_state()
        existing_snapshot = self.store.load_snapshot()
        existing_by_store = _group_by_store(load_releases_from_snapshot(existing_snapshot))

        normalized: List[Release] = []
        per_source: Dict[str, int] = {}
        failed_sources: Dict[str, str] = {}
        warnings: List[str] = []

        for adapter in self.adapters:
            source = adapter.source
            try:
                raws = adapter.fetch_latest(now)
                warnings.extend(adapter.pop_warnings())
                if not raws and existing_by_store.get(adapter.store_id):
                    warning_key = f"{source}_empty_parse_failure"
                    warnings.append(warning_key)
                    fallback = existing_by_store.get(adapter.store_id, [])
                    normalized.extend(fallback)
                    per_source[source] = len(fallback)
                    logger.warning("source=%s warning=%s fallback=%d", source, warning_key, len(fallback))
                    continue

                missing_source_publish_time = sum(1 for raw in raws if raw.published_at is None)
                if missing_source_publish_time > 0:
                    warnings.append(f"missing_source_publish_time:{source}:{missing_source_publish_time}")

                converted = [self._normalize(raw, state, now) for raw in raws]
                normalized.extend(converted)
                per_source[source] = len(converted)
                logger.info("source=%s fetched=%d", source, len(converted))
            except Exception as exc:  # noqa: BLE001
                warnings.extend(adapter.pop_warnings())
                failed_sources[source] = str(exc)
                fallback = existing_by_store.get(adapter.store_id, [])
                normalized.extend(fallback)
                per_source[source] = len(fallback)
                logger.warning("source=%s failed=%s fallback=%d", source, exc, len(fallback))

        merged = dedupe_within_store(normalized)
        generated_at = to_iso8601(now)
        refresh_meta = _build_refresh_meta(
            generated_at=generated_at,
            per_source=per_source,
            failed_sources=failed_sources,
            warnings=warnings,
        )

        self.store.save_state(state)
        self.store.save_snapshot(generated_at, merged, refresh_meta=refresh_meta)

        return RefreshMetrics(
            generated_at=generated_at,
            total=len(merged),
            per_source=per_source,
            failed_sources=failed_sources,
            warnings=warnings,
        )

    def _normalize(self, raw: RawRelease, state: FeedState, now: datetime) -> Release:
        now_iso = to_iso8601(now)
        first_seen_iso = resolve_first_seen(state, raw.store_id, raw.source_item_key, now_iso)
        first_seen_at = parse_first_seen(first_seen_iso)

        text_for_flags = " ".join(
            part for part in [raw.artist, raw.title, raw.subtitle, raw.description] if part
        )
        flags = classify_flags(
            text_for_flags,
            first_seen_at=first_seen_at,
            now=now,
            source=raw.source,
        )

        published_at = raw.published_at or first_seen_at
        published_at_source = "source" if raw.published_at else "first_seen"
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
            publishedAtSource=published_at_source,
            flags=flags,
            description=raw.description,
            isSoldOut=raw.is_sold_out,
            signedByHeuristic=raw.signed_by_heuristic,
        )


def _group_by_store(releases: Iterable[Release]) -> Dict[str, List[Release]]:
    grouped: Dict[str, List[Release]] = {}
    for release in releases:
        grouped.setdefault(release.storeID, []).append(release)
    return grouped


def _build_refresh_meta(
    generated_at: str,
    per_source: Dict[str, int],
    failed_sources: Dict[str, str],
    warnings: List[str],
) -> Dict[str, Any]:
    return {
        "generatedAt": generated_at,
        "perSource": per_source,
        "failedSources": failed_sources,
        "warnings": warnings,
    }
