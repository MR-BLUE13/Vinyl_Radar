from __future__ import annotations

from datetime import datetime
from typing import List

from .shopify_base import ShopifyCollectionAdapter
from .html_utils import (
    extract_product_metadata,
    extract_shopify_product_entries,
    fetch_html,
    resolve_artist_and_title,
)
from ..models import RawRelease


class BloodRecordsAdapter(ShopifyCollectionAdapter):
    source = "blood_records"
    store_id = "store_blood_records"
    entry_url = "https://blood-records.co.uk/collections/drops"

    def fetch_from_html_fallback(self, now: datetime) -> List[RawRelease]:
        html_text = fetch_html(self.entry_url, timeout=4)
        entries = extract_shopify_product_entries(self.entry_url, html_text, limit=30)
        releases: List[RawRelease] = []
        for href, text in entries:
            metadata = _safe_fetch_metadata(href)
            artist, title = resolve_artist_and_title(text, metadata)
            releases.append(
                RawRelease(
                    source=self.source,
                    store_id=self.store_id,
                    source_item_key=href,
                    artist=artist,
                    title=title,
                    source_item_url=href,
                    cover_image_url=metadata.cover_image_url if metadata else None,
                    description=metadata.description if metadata else None,
                    is_sold_out=False,
                    published_at=metadata.published_at if metadata else None,
                )
            )
        return releases


def _safe_fetch_metadata(url: str):
    try:
        product_html = fetch_html(url, timeout=4)
    except Exception:  # noqa: BLE001
        return None
    return extract_product_metadata(url, product_html)
