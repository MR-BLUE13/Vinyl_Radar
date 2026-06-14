from __future__ import annotations

from datetime import datetime
from typing import Iterable, List

from .base import SourceAdapter
from .html_utils import (
    ListingEntry,
    extract_banquet_listing_entries,
    extract_product_metadata,
    fetch_html,
    is_event_like_listing,
    resolve_artist_and_title,
)
from ..models import RawRelease


class BanquetRecordsAdapter(SourceAdapter):
    source = "banquet_records"
    store_id = "store_banquet_records"
    entry_url = "https://www.banquetrecords.com/pre-orders"
    home_url = "https://www.banquetrecords.com/"

    def fetch_latest(self, now: datetime) -> List[RawRelease]:
        self._warnings = []
        entries = self._collect_entries()
        if not entries:
            raise RuntimeError("banquet_records_empty_after_merge")

        releases: List[RawRelease] = []
        for entry in entries:
            if is_event_like_listing(entry.text):
                continue

            metadata = _safe_fetch_metadata(entry.href)
            if _is_event_entry(metadata):
                continue

            artist, title = resolve_artist_and_title(entry.text, metadata)
            sold_out = _is_sold_out_text(entry.text)
            if metadata and metadata.description:
                sold_out = sold_out or _is_sold_out_text(metadata.description)
            if metadata and metadata.title:
                sold_out = sold_out or _is_sold_out_text(metadata.title)
            if _contains_back_in_stock(entry.text):
                sold_out = False

            releases.append(
                RawRelease(
                    source=self.source,
                    store_id=self.store_id,
                    source_item_key=entry.href,
                    artist=artist,
                    title=title,
                    source_item_url=entry.href,
                    cover_image_url=_pick_cover(entry, metadata),
                    description=metadata.description if metadata else None,
                    is_sold_out=sold_out,
                    published_at=metadata.published_at if metadata else None,
                )
            )
        return releases

    def _collect_entries(self) -> List[ListingEntry]:
        home_entries = self._fetch_listing_entries(self.home_url, endpoint_key="home")
        preorders_entries = self._fetch_listing_entries(self.entry_url, endpoint_key="preorders")

        if not home_entries and not preorders_entries:
            raise RuntimeError("banquet_records_no_entries_from_all_endpoints")

        merged: List[ListingEntry] = []
        seen: set[str] = set()
        for entry in _prioritize_entries(home_entries, preorders_entries):
            if entry.href in seen:
                continue
            seen.add(entry.href)
            merged.append(entry)
            if len(merged) >= 40:
                break
        return merged

    def _fetch_listing_entries(self, url: str, endpoint_key: str) -> List[ListingEntry]:
        try:
            html = fetch_html(url, timeout=4)
        except Exception as exc:  # noqa: BLE001
            self.add_warning(f"banquet_{endpoint_key}_fetch_failed:{type(exc).__name__}")
            return []

        entries = extract_banquet_listing_entries(url, html, limit=40)
        if not entries:
            self.add_warning(f"banquet_{endpoint_key}_empty_parse")
        return entries


def _prioritize_entries(home_entries: List[ListingEntry], preorder_entries: List[ListingEntry]) -> Iterable[ListingEntry]:
    # Keep homepage featured entries first, then pre-orders.
    for entry in home_entries:
        yield entry
    for entry in preorder_entries:
        yield entry


def _pick_cover(entry: ListingEntry, metadata) -> str | None:
    if entry.image_url:
        return entry.image_url
    if metadata and metadata.cover_image_url:
        return metadata.cover_image_url
    return None


def _safe_fetch_metadata(url: str):
    try:
        product_html = fetch_html(url, timeout=4)
    except Exception:  # noqa: BLE001
        return None
    return extract_product_metadata(url, product_html)


def _is_event_entry(metadata) -> bool:
    if not metadata:
        return False
    if metadata.title and is_event_like_listing(metadata.title):
        return True
    if metadata.description and is_event_like_listing(metadata.description):
        return True
    return False


def _is_sold_out_text(text: str) -> bool:
    lowered = text.lower()
    return "sold out" in lowered or "out of stock" in lowered


def _contains_back_in_stock(text: str) -> bool:
    return "back in stock" in text.lower()
