from __future__ import annotations

import json
from datetime import datetime
from typing import Dict, List, Optional
from urllib.parse import urlparse

from .base import SourceAdapter
from .html_utils import (
    clean_description,
    extract_artist_from_description,
    is_store_like_artist,
    is_valid_cover_image,
    parse_external_datetime,
    split_artist_and_title,
)
from ..models import RawRelease


class ShopifyCollectionAdapter(SourceAdapter):
    json_limit = 250

    def fetch_latest(self, now: datetime) -> List[RawRelease]:
        self._warnings = []

        releases = self._fetch_from_products_json(now)
        if releases:
            return releases

        self.add_warning(f"{self.source}_json_empty")
        return self.fetch_from_html_fallback(now)

    def fetch_from_html_fallback(self, now: datetime) -> List[RawRelease]:
        raise NotImplementedError

    def _fetch_from_products_json(self, now: datetime) -> List[RawRelease]:
        releases: List[RawRelease] = []
        for url in self._products_json_urls():
            try:
                payload = self._fetch_json_payload(url)
            except Exception as exc:  # noqa: BLE001
                self.add_warning(f"{self.source}_json_fetch_failed:{url}:{type(exc).__name__}")
                continue

            try:
                data = json.loads(payload)
            except json.JSONDecodeError:
                self.add_warning(f"{self.source}_json_decode_failed:{url}")
                continue

            products = data.get("products", [])
            if not isinstance(products, list) or not products:
                self.add_warning(f"{self.source}_json_no_products:{url}")
                continue

            for product in products:
                release = self._map_product(product=product, now=now)
                if release:
                    releases.append(release)

            if releases:
                return releases[: self.json_limit]

        return releases[: self.json_limit]

    def _products_json_urls(self) -> List[str]:
        configured = getattr(self, "products_json_urls", None)
        if isinstance(configured, list) and configured:
            return configured
        base = self.entry_url.rstrip("/")
        return [f"{base}/products.json?limit={self.json_limit}"]

    def _fetch_json_payload(self, url: str) -> str:
        from .html_utils import fetch_html  # local import to avoid cycles

        return fetch_html(url, timeout=4)

    def _map_product(self, product: Dict, now: datetime) -> Optional[RawRelease]:
        handle = str(product.get("handle", "")).strip()
        title_raw = str(product.get("title", "")).strip()
        if not handle or not title_raw:
            return None

        vendor = str(product.get("vendor", "")).strip()
        split_artist, split_title = split_artist_and_title(title_raw)
        description = clean_description(product.get("body_html"))
        description_artist = extract_artist_from_description(description)

        vendor_artist = ""
        if vendor and not is_store_like_artist(vendor):
            vendor_artist = vendor

        artist = split_artist or description_artist or vendor_artist or "Unknown Artist"
        title = split_title if split_artist else title_raw

        image_url = _extract_shopify_cover_image(product)
        source_item_url = self._build_product_url(handle)
        source_item_key = source_item_url

        is_sold_out = _is_shopify_sold_out(product)
        published_at = _extract_shopify_published_at(product)

        return RawRelease(
            source=self.source,
            store_id=self.store_id,
            source_item_key=source_item_key,
            artist=artist,
            title=title,
            source_item_url=source_item_url,
            cover_image_url=image_url,
            description=description,
            is_sold_out=is_sold_out,
            published_at=published_at,
        )

    def _build_product_url(self, handle: str) -> str:
        parsed = urlparse(self.entry_url)
        origin = f"{parsed.scheme}://{parsed.netloc}"
        return f"{origin}/products/{handle}"


def _extract_shopify_cover_image(product: Dict) -> Optional[str]:
    candidates: List[str] = []

    image = product.get("image")
    if isinstance(image, dict):
        src = image.get("src") or image.get("url")
        if isinstance(src, str):
            candidates.append(src)

    images = product.get("images", [])
    if isinstance(images, list):
        for item in images:
            if isinstance(item, dict):
                src = item.get("src") or item.get("url")
                if isinstance(src, str):
                    candidates.append(src)
            elif isinstance(item, str):
                candidates.append(item)

    for candidate in candidates:
        if is_valid_cover_image(candidate):
            return candidate
    return None


def _is_shopify_sold_out(product: Dict) -> bool:
    variants = product.get("variants", [])
    if not isinstance(variants, list) or not variants:
        return False

    has_available_variant = False
    for variant in variants:
        if not isinstance(variant, dict):
            continue
        available = variant.get("available")
        if isinstance(available, bool):
            has_available_variant = has_available_variant or available
            continue

        inventory_quantity = variant.get("inventory_quantity")
        if isinstance(inventory_quantity, (int, float)) and inventory_quantity > 0:
            has_available_variant = True

    return not has_available_variant


def _extract_shopify_published_at(product: Dict) -> Optional[datetime]:
    for key in (
        "published_at",
        "publishedAt",
        "created_at",
        "createdAt",
        "updated_at",
        "updatedAt",
    ):
        parsed = parse_external_datetime(product.get(key))
        if parsed:
            return parsed
    return None
