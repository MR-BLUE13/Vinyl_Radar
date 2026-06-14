from __future__ import annotations

from dataclasses import replace
from datetime import datetime
import json
import re
from typing import Dict, List, Optional, Tuple
from urllib.error import HTTPError
from urllib.parse import urljoin, urlparse

from .html_utils import (
    clean_text,
    extract_product_metadata,
    extract_shopify_product_entries,
    fetch_html,
    resolve_artist_and_title,
)
from .shopify_base import ShopifyCollectionAdapter
from ..models import RawRelease


SIGNED_KEYWORDS = (
    "signed",
    "personally signed",
    "autographed",
    "hand-signed",
    "signature",
    "signed print",
    "签名",
    "亲签",
)

NON_VINYL_KEYWORDS = (
    "ticket",
    "tickets",
    "event",
    "book",
    "cassette",
    "cd",
    "merch",
    "t-shirt",
    "slipmat",
    "gift card",
)

ENTRY_PATH_KEYWORDS = (
    "/products/",
    "/product/",
    "/release/",
    "/releases/",
    "/album/",
    "/albums/",
    "/records/",
)

INVALID_PATH_MARKERS = (
    "/search",
    "/collections",
    "/pages",
    "/blogs",
    "/account",
    "/cart",
    "/checkout",
)

GENERIC_LINK_TEXT = {"read more", "shop", "view all", "pre-order", "buy now"}


class RoughTradeUSAdapter(ShopifyCollectionAdapter):
    source = "rough_trade_us"
    store_id = "store_rough_trade_us"
    entry_url = "https://www.roughtrade.com/us"
    products_json_urls = [
        "https://www.roughtrade.com/us/collections/new-this-week/products.json?limit=250",
        "https://www.roughtrade.com/us/collections/pre-orders/products.json?limit=250",
        "https://www.roughtrade.com/us/products.json?limit=250",
    ]
    entry_urls = [
        "https://www.roughtrade.com/us/collections/new-this-week",
        "https://www.roughtrade.com/us/collections/pre-orders",
        "https://www.roughtrade.com/us",
        "https://shop.roughtraderecords.com/new-releases?lang=en_US",
        "https://shop.roughtraderecords.com/new-releases",
    ]
    json_limit = 250
    max_items = 40

    def fetch_latest(self, now: datetime) -> List[RawRelease]:
        releases = super().fetch_latest(now)
        return releases[: self.max_items]

    def _map_product(self, product: Dict, now: datetime) -> Optional[RawRelease]:
        release = super()._map_product(product=product, now=now)
        if release is None:
            return None

        combined_text = " ".join(part for part in [release.artist, release.title, release.description] if part)
        if _is_non_vinyl_entry(combined_text):
            return None

        signed_by_heuristic = release.signed_by_heuristic or _contains_signed_keywords(combined_text)
        return replace(release, signed_by_heuristic=signed_by_heuristic)

    def fetch_from_html_fallback(self, now: datetime) -> List[RawRelease]:
        entries = self._collect_entries()
        if not entries:
            raise RuntimeError("rough_trade_us_no_entries")

        releases: List[RawRelease] = []
        for href, text in entries:
            if _is_non_vinyl_entry(text):
                continue

            metadata = _safe_fetch_metadata(self, href)
            if metadata:
                metadata_text = " ".join(part for part in [metadata.title, metadata.description] if part)
                if _is_non_vinyl_entry(metadata_text):
                    continue

            artist, title = resolve_artist_and_title(text, metadata)
            combined_text = " ".join(part for part in [text, title, metadata.description if metadata else None] if part)
            signed_by_heuristic = _contains_signed_keywords(combined_text)

            sold_out = _is_sold_out_text(text)
            if metadata and metadata.description:
                sold_out = sold_out or _is_sold_out_text(metadata.description)
            if metadata and metadata.title:
                sold_out = sold_out or _is_sold_out_text(metadata.title)
            if _contains_back_in_stock(combined_text):
                sold_out = False

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
                    is_sold_out=sold_out,
                    published_at=metadata.published_at if metadata else None,
                    signed_by_heuristic=signed_by_heuristic,
                )
            )

            if len(releases) >= self.max_items:
                break

        return releases

    def _collect_entries(self) -> List[Tuple[str, str]]:
        merged: List[Tuple[str, str]] = []
        seen: set[str] = set()

        for url in self.entry_urls:
            try:
                html_text = fetch_html(url, timeout=4, headers=_browser_headers(url))
            except Exception as exc:  # noqa: BLE001
                self.add_warning(_classify_fetch_error(url, exc))
                continue

            entries = _extract_rough_trade_entries(url, html_text, limit=80)
            if not entries:
                entries = _extract_rough_trade_json_ld_entries(url, html_text, limit=80)
            if not entries:
                self.add_warning(f"rough_trade_us_empty_parse:{url}")
                continue

            for href, text in entries:
                if href in seen:
                    continue
                seen.add(href)
                merged.append((href, text))
                if len(merged) >= self.max_items:
                    return merged

        return merged


def _safe_fetch_metadata(adapter: RoughTradeUSAdapter, url: str):
    try:
        product_html = fetch_html(url, timeout=4, headers=_browser_headers(url))
    except Exception as exc:  # noqa: BLE001
        adapter.add_warning(_classify_fetch_error(url, exc, context="metadata"))
        return None
    return extract_product_metadata(url, product_html)


def _contains_signed_keywords(text: str) -> bool:
    lowered = clean_text(text).lower().replace("unsigned", "")
    return any(keyword in lowered for keyword in SIGNED_KEYWORDS)


def _is_non_vinyl_entry(text: str) -> bool:
    lowered = clean_text(text).lower()
    if not lowered:
        return True
    return any(keyword in lowered for keyword in NON_VINYL_KEYWORDS)


def _is_sold_out_text(text: str) -> bool:
    lowered = clean_text(text).lower()
    return "sold out" in lowered or "out of stock" in lowered


def _contains_back_in_stock(text: str) -> bool:
    return "back in stock" in clean_text(text).lower()


def _extract_rough_trade_entries(base_url: str, html_text: str, limit: int = 80) -> List[Tuple[str, str]]:
    entries = extract_shopify_product_entries(base_url, html_text, limit=limit)
    if entries:
        return entries

    anchor_pattern = re.compile(
        r"<a[^>]+href=[\"'](?P<href>[^\"']+)[\"'][^>]*>(?P<text>.*?)</a>",
        flags=re.IGNORECASE | re.DOTALL,
    )

    deduped: List[Tuple[str, str]] = []
    seen: set[str] = set()

    for match in anchor_pattern.finditer(html_text):
        href = match.group("href")
        absolute = urljoin(base_url, href)
        parsed = urlparse(absolute)
        path = parsed.path.lower()

        if parsed.scheme not in {"http", "https"}:
            continue
        if not any(marker in path for marker in ENTRY_PATH_KEYWORDS):
            continue
        if any(marker in path for marker in INVALID_PATH_MARKERS):
            continue

        text = clean_text(re.sub(r"<[^>]+>", " ", match.group("text")))
        lowered = text.lower()
        if len(lowered) < 3 or len(lowered) > 220:
            continue
        if lowered in GENERIC_LINK_TEXT:
            continue

        if absolute in seen:
            continue
        seen.add(absolute)
        deduped.append((absolute, text))

        if len(deduped) >= limit:
            break

    return deduped


def _extract_rough_trade_json_ld_entries(base_url: str, html_text: str, limit: int = 80) -> List[Tuple[str, str]]:
    scripts = _extract_json_ld_scripts(html_text)
    if not scripts:
        return []

    deduped: List[Tuple[str, str]] = []
    seen: set[str] = set()

    for script in scripts:
        try:
            payload = json.loads(script)
        except json.JSONDecodeError:
            continue

        for node in _walk_nodes(payload):
            node_types = _normalize_types(node.get("@type"))

            # ItemList path
            if "itemlist" in node_types:
                elements = node.get("itemListElement")
                if isinstance(elements, list):
                    for element in elements:
                        href, text = _itemlist_entry(base_url, element)
                        if not href:
                            continue
                        if href in seen:
                            continue
                        seen.add(href)
                        deduped.append((href, text))
                        if len(deduped) >= limit:
                            return deduped

            # Product node path
            if "product" in node_types:
                href = _normalize_entry_url(base_url, _coerce_text(node.get("url")))
                if not href:
                    continue
                text = _coerce_text(node.get("name")) or "Untitled"
                if href in seen:
                    continue
                seen.add(href)
                deduped.append((href, text))
                if len(deduped) >= limit:
                    return deduped

    return deduped


def _extract_json_ld_scripts(html_text: str) -> List[str]:
    pattern = re.compile(
        r"<script[^>]*type=[\"'][^\"']*ld\+json[^\"']*[\"'][^>]*>(?P<body>.*?)</script>",
        flags=re.IGNORECASE | re.DOTALL,
    )
    return [match.group("body").strip() for match in pattern.finditer(html_text) if match.group("body")]


def _walk_nodes(payload):
    if isinstance(payload, dict):
        yield payload
        for value in payload.values():
            yield from _walk_nodes(value)
    elif isinstance(payload, list):
        for value in payload:
            yield from _walk_nodes(value)


def _normalize_types(value) -> List[str]:
    if isinstance(value, str):
        return [value.lower()]
    if isinstance(value, list):
        return [item.lower() for item in value if isinstance(item, str)]
    return []


def _coerce_text(value) -> Optional[str]:
    if not isinstance(value, str):
        return None
    text = clean_text(value)
    return text or None


def _itemlist_entry(base_url: str, element) -> Tuple[Optional[str], str]:
    if not isinstance(element, dict):
        return None, ""

    item = element.get("item")
    if isinstance(item, dict):
        href_raw = _coerce_text(item.get("url"))
        text = _coerce_text(item.get("name")) or _coerce_text(element.get("name")) or "Untitled"
    else:
        href_raw = _coerce_text(item) or _coerce_text(element.get("url"))
        text = _coerce_text(element.get("name")) or "Untitled"

    href = _normalize_entry_url(base_url, href_raw)
    return href, text


def _normalize_entry_url(base_url: str, candidate: Optional[str]) -> Optional[str]:
    if not candidate:
        return None
    absolute = urljoin(base_url, candidate)
    parsed = urlparse(absolute)
    path = parsed.path.lower()

    if parsed.scheme not in {"http", "https"}:
        return None
    if not any(marker in path for marker in ENTRY_PATH_KEYWORDS):
        return None
    if any(marker in path for marker in INVALID_PATH_MARKERS):
        return None
    return absolute


def _browser_headers(url: str) -> Dict[str, str]:
    parsed = urlparse(url)
    origin = f"{parsed.scheme}://{parsed.netloc}" if parsed.scheme and parsed.netloc else "https://www.roughtrade.com"
    return {
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/124.0.0.0 Safari/537.36"
        ),
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
        "Referer": origin,
        "Cache-Control": "no-cache",
    }


def _classify_fetch_error(url: str, exc: Exception, context: str = "listing") -> str:
    error_type = type(exc).__name__
    if isinstance(exc, HTTPError):
        if exc.code in {401, 403, 429}:
            return f"rough_trade_us_blocked_or_403:{context}:{url}:{exc.code}"
        return f"rough_trade_us_fetch_failed:{context}:{url}:{exc.code}"
    return f"rough_trade_us_fetch_failed:{context}:{url}:{error_type}"
