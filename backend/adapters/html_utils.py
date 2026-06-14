from __future__ import annotations

import html
import json
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from html.parser import HTMLParser
from typing import Any, Dict, Iterable, List, Optional, Tuple
from urllib.parse import urljoin, urlparse
from urllib.request import Request, urlopen


GENERIC_LINK_TEXT = {"read more", "shop", "view all", "pre-order", "buy now"}
BANQUET_RESERVED_FIRST_SEGMENT = {
    "pre-orders",
    "new-releases",
    "search",
    "basket",
    "account",
    "checkout",
    "artists",
    "labels",
    "events",
    "news",
    "contact",
}
INVALID_COVER_IMAGE_MARKERS = (
    "placeholder-vinyl.png",
    "icon-search.svg",
    "logo-symbol.svg",
)
SITE_NAME_MARKERS = ("blood records", "bad world", "banquet records")
STORE_ARTIST_EXACT = {
    "blood records",
    "bad world",
    "badworldrecords",
    "banquet records",
    "rough trade",
    "rough trade us",
}
STORE_ARTIST_COMPACT = {
    "bloodrecords",
    "badworld",
    "badworldrecords",
    "banquetrecords",
    "roughtrade",
    "roughtradeus",
}
EVENT_KEYWORDS = {
    "listening party",
    "tickets",
    "ticket",
    "admission",
}
EVENT_DAY_PATTERN = re.compile(
    r"\b(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b.*\b\d{1,2}(?:st|nd|rd|th)\b.*\bat\b",
    flags=re.IGNORECASE,
)
EVENT_TIME_PATTERN = re.compile(r"\b\d{1,2}:\d{2}\s*(?:am|pm)\b", flags=re.IGNORECASE)
EVENT_AGE_PATTERN = re.compile(r"\(\d{1,2}\+\)")
BODY_DATE_DMY_PATTERN = re.compile(
    r"\b(\d{1,2})(?:st|nd|rd|th)?\s+"
    r"(january|february|march|april|may|june|july|august|september|october|november|december|"
    r"jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)"
    r"\s+(\d{4})\b",
    flags=re.IGNORECASE,
)
BODY_DATE_MDY_PATTERN = re.compile(
    r"\b("
    r"january|february|march|april|may|june|july|august|september|october|november|december|"
    r"jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec"
    r")\s+(\d{1,2})(?:st|nd|rd|th)?(?:,)?\s+(\d{4})\b",
    flags=re.IGNORECASE,
)
MONTH_TO_NUMBER = {
    "jan": 1,
    "january": 1,
    "feb": 2,
    "february": 2,
    "mar": 3,
    "march": 3,
    "apr": 4,
    "april": 4,
    "may": 5,
    "jun": 6,
    "june": 6,
    "jul": 7,
    "july": 7,
    "aug": 8,
    "august": 8,
    "sep": 9,
    "sept": 9,
    "september": 9,
    "oct": 10,
    "october": 10,
    "nov": 11,
    "november": 11,
    "dec": 12,
    "december": 12,
}
DESCRIPTION_ARTIST_PATTERNS = [
    re.compile(
        r"([A-Za-z0-9][A-Za-z0-9&'.\-]*(?:\s+[A-Za-z0-9][A-Za-z0-9&'.\-]*){0,4})['’]s\s+(?:[^.]{0,50})\balbum\b",
        flags=re.IGNORECASE,
    ),
    re.compile(
        r"([A-Za-z0-9][A-Za-z0-9&'.\-]*(?:\s+[A-Za-z0-9][A-Za-z0-9&'.\-]*){0,4})\s+(?:releases|returns|return)\b",
        flags=re.IGNORECASE,
    ),
    re.compile(
        r"\bby\s+([A-Z0-9][A-Za-z0-9&'.\-]*(?:\s+[A-Z0-9][A-Za-z0-9&'.\-]*){0,4})\b",
    ),
]


def clean_text(value: str) -> str:
    text = html.unescape(value)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def fetch_html(url: str, timeout: int = 4, headers: Optional[Dict[str, str]] = None) -> str:
    request_headers = {
        "User-Agent": "VinylRadarBot/1.2 (+https://example.local)",
        "Accept": "text/html,application/xhtml+xml",
    }
    if headers:
        request_headers.update(headers)

    request = Request(
        url,
        headers=request_headers,
    )
    with urlopen(request, timeout=timeout) as response:
        return response.read().decode("utf-8", errors="ignore")


@dataclass(frozen=True)
class ProductMetadata:
    title: Optional[str] = None
    artist: Optional[str] = None
    cover_image_url: Optional[str] = None
    description: Optional[str] = None
    published_at: Optional[datetime] = None


@dataclass(frozen=True)
class ListingEntry:
    href: str
    text: str
    image_url: Optional[str] = None


class _AnchorParser(HTMLParser):
    def __init__(self, base_url: str) -> None:
        super().__init__()
        self.base_url = base_url
        self.links: List[Tuple[str, str]] = []
        self._in_anchor = False
        self._anchor_href = ""
        self._anchor_chunks: List[str] = []

    def handle_starttag(self, tag: str, attrs):
        if tag != "a":
            return
        attrs_dict = dict(attrs)
        href = attrs_dict.get("href", "")
        self._in_anchor = True
        self._anchor_href = href
        self._anchor_chunks = []

    def handle_data(self, data: str):
        if self._in_anchor:
            self._anchor_chunks.append(data)

    def handle_endtag(self, tag: str):
        if tag != "a":
            return
        self._in_anchor = False
        href = self._anchor_href
        text = clean_text("".join(self._anchor_chunks))
        if href and text:
            self.links.append((urljoin(self.base_url, href), text))
        self._anchor_href = ""
        self._anchor_chunks = []


class _LinkedCardParser(HTMLParser):
    def __init__(self, base_url: str) -> None:
        super().__init__()
        self.base_url = base_url
        self.entries: List[ListingEntry] = []

        self._in_anchor = False
        self._anchor_href = ""
        self._anchor_chunks: List[str] = []
        self._anchor_img: Optional[str] = None
        self._anchor_title_attr = ""

    def handle_starttag(self, tag: str, attrs):
        attrs_dict = dict(attrs)
        if tag == "a":
            self._in_anchor = True
            self._anchor_href = attrs_dict.get("href", "")
            self._anchor_chunks = []
            self._anchor_img = None
            self._anchor_title_attr = clean_text(attrs_dict.get("title", ""))
            return

        if not self._in_anchor:
            return

        if tag == "img":
            src = attrs_dict.get("src") or attrs_dict.get("data-src")
            if src and self._anchor_img is None:
                self._anchor_img = urljoin(self.base_url, src)

    def handle_data(self, data: str):
        if self._in_anchor:
            self._anchor_chunks.append(data)

    def handle_endtag(self, tag: str):
        if tag != "a":
            return
        self._in_anchor = False

        href = self._anchor_href
        text = clean_text("".join(self._anchor_chunks)) or self._anchor_title_attr
        if href and text:
            self.entries.append(
                ListingEntry(
                    href=urljoin(self.base_url, href),
                    text=text,
                    image_url=self._anchor_img,
                )
            )

        self._anchor_href = ""
        self._anchor_chunks = []
        self._anchor_img = None
        self._anchor_title_attr = ""


class _MetadataParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.meta: Dict[str, str] = {}
        self._capture_json_ld = False
        self._json_ld_chunks: List[str] = []
        self.json_ld_scripts: List[str] = []

    def handle_starttag(self, tag: str, attrs):
        attrs_dict = dict(attrs)
        if tag == "meta":
            key = (attrs_dict.get("property") or attrs_dict.get("name") or "").strip().lower()
            content = clean_text(attrs_dict.get("content", ""))
            if key and content:
                self.meta[key] = content
            return

        if tag == "script":
            script_type = (attrs_dict.get("type") or "").strip().lower()
            if "ld+json" in script_type:
                self._capture_json_ld = True
                self._json_ld_chunks = []

    def handle_data(self, data: str):
        if self._capture_json_ld:
            self._json_ld_chunks.append(data)

    def handle_endtag(self, tag: str):
        if tag == "script" and self._capture_json_ld:
            payload = "".join(self._json_ld_chunks).strip()
            if payload:
                self.json_ld_scripts.append(payload)
            self._capture_json_ld = False
            self._json_ld_chunks = []


class _ImageParser(HTMLParser):
    def __init__(self, base_url: str) -> None:
        super().__init__()
        self.base_url = base_url
        self.images: List[str] = []

    def handle_starttag(self, tag: str, attrs):
        if tag != "img":
            return
        attrs_dict = dict(attrs)
        src = attrs_dict.get("src") or attrs_dict.get("data-src")
        if src:
            self.images.append(urljoin(self.base_url, src))


def extract_shopify_product_entries(base_url: str, html_text: str, limit: int = 30) -> List[Tuple[str, str]]:
    parser = _AnchorParser(base_url)
    parser.feed(html_text)

    candidates: List[Tuple[str, str]] = []
    for href, text in parser.links:
        lowered_path = urlparse(href).path.lower()
        if "/products/" not in lowered_path:
            continue
        if not _is_reasonable_link_text(text):
            continue
        candidates.append((href, text))

    return _dedupe_links(candidates, limit=limit)


def extract_banquet_listing_entries(base_url: str, html_text: str, limit: int = 30) -> List[ListingEntry]:
    parser = _LinkedCardParser(base_url)
    parser.feed(html_text)

    candidates: List[ListingEntry] = []
    for entry in parser.entries:
        parsed = urlparse(entry.href)
        host = parsed.netloc.lower()
        if host not in {"banquetrecords.com", "www.banquetrecords.com"}:
            continue

        segments = [segment for segment in parsed.path.split("/") if segment]
        if len(segments) != 3:
            continue
        if segments[0].lower() in BANQUET_RESERVED_FIRST_SEGMENT:
            continue
        if not _is_reasonable_link_text(entry.text):
            continue

        image = entry.image_url if is_valid_cover_image(entry.image_url) else None
        candidates.append(ListingEntry(href=entry.href, text=entry.text, image_url=image))

    return _dedupe_listing_entries(candidates, limit=limit)


def extract_banquet_product_entries(base_url: str, html_text: str, limit: int = 30) -> List[Tuple[str, str]]:
    return [(entry.href, entry.text) for entry in extract_banquet_listing_entries(base_url, html_text, limit=limit)]


def extract_product_metadata(base_url: str, html_text: str) -> ProductMetadata:
    parser = _MetadataParser()
    parser.feed(html_text)

    json_ld = _extract_json_ld_product(parser.json_ld_scripts, base_url)
    image_url = _first_valid_cover_image(
        [
            json_ld.get("image"),
            parser.meta.get("og:image"),
            parser.meta.get("twitter:image"),
            extract_first_valid_image(base_url, html_text),
        ],
        base_url=base_url,
    )

    description = clean_description(
        json_ld.get("description")
        or parser.meta.get("og:description")
        or parser.meta.get("description")
        or extract_description_from_html(html_text)
    )
    title = _clean_title(
        json_ld.get("name")
        or parser.meta.get("og:title")
        or parser.meta.get("twitter:title")
        or parser.meta.get("title")
    )
    artist = clean_text(json_ld.get("artist", "")) or None
    published_at = parse_external_datetime(
        json_ld.get("publishedAt")
        or parser.meta.get("article:published_time")
        or parser.meta.get("og:published_time")
        or parser.meta.get("product:release_date")
        or parser.meta.get("release_date")
        or extract_published_at_from_html(html_text)
    )

    return ProductMetadata(
        title=title,
        artist=artist,
        cover_image_url=image_url,
        description=description,
        published_at=published_at,
    )


def resolve_artist_and_title(listing_text: str, metadata: Optional[ProductMetadata]) -> Tuple[str, str]:
    list_artist, list_title = split_artist_and_title(listing_text)
    list_artist = sanitize_artist_candidate(list_artist) or ""

    meta_artist = sanitize_artist_candidate(metadata.artist) if metadata and metadata.artist else ""
    meta_title = _clean_title(metadata.title) if metadata and metadata.title else None

    if meta_title:
        title_artist, title_value = split_artist_and_title(meta_title)
        title_artist = sanitize_artist_candidate(title_artist) or ""
        if not meta_artist and title_artist:
            meta_artist = title_artist
        meta_title = title_value

    artist = meta_artist or list_artist or "Unknown Artist"
    title = meta_title or list_title or clean_text(listing_text) or "Untitled"

    return artist, title


def split_artist_and_title(text: str) -> Tuple[str, str]:
    value = clean_text(text)
    if not value:
        return "", ""

    dash_match = re.match(r"^(?P<artist>.+?)\s*[-:]\s*(?P<title>.+)$", value)
    if dash_match:
        return clean_text(dash_match.group("artist")), clean_text(dash_match.group("title"))

    by_match = re.match(r"^(?P<title>.+?)\s+by\s+(?P<artist>.+)$", value, flags=re.IGNORECASE)
    if by_match:
        return clean_text(by_match.group("artist")), clean_text(by_match.group("title"))

    return "", value


def sanitize_artist_candidate(value: Optional[str]) -> Optional[str]:
    if not value:
        return None

    candidate = clean_text(value)
    candidate = re.sub(r"^[^A-Za-z0-9]+|[^A-Za-z0-9]+$", "", candidate)
    candidate = clean_text(candidate)
    if not candidate:
        return None
    if is_store_like_artist(candidate):
        return None
    return candidate


def is_store_like_artist(value: Optional[str]) -> bool:
    if not value:
        return False

    cleaned = clean_text(value).lower()
    compact = re.sub(r"[^a-z0-9]", "", cleaned)

    if cleaned in STORE_ARTIST_EXACT:
        return True
    if compact in STORE_ARTIST_COMPACT:
        return True
    return False


def extract_artist_from_description(value: Optional[str]) -> Optional[str]:
    if not value:
        return None

    description = clean_text(value)
    if not description:
        return None

    for pattern in DESCRIPTION_ARTIST_PATTERNS:
        for match in pattern.finditer(description):
            candidate = sanitize_artist_candidate(match.group(1))
            if not candidate:
                continue
            if len(candidate.split()) > 5:
                continue
            return candidate
    return None


def parse_external_datetime(value: Any) -> Optional[datetime]:
    if value is None:
        return None

    if isinstance(value, datetime):
        if value.tzinfo is None:
            return value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc)

    if isinstance(value, (int, float)):
        try:
            return datetime.fromtimestamp(float(value), tz=timezone.utc)
        except (TypeError, ValueError, OSError):
            return None

    if not isinstance(value, str):
        return None

    candidate = clean_text(value)
    if not candidate:
        return None

    iso_candidate = candidate.replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(iso_candidate)
        if parsed.tzinfo is None:
            return parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(timezone.utc)
    except ValueError:
        pass

    for fmt in ("%Y-%m-%d", "%Y/%m/%d"):
        try:
            parsed = datetime.strptime(candidate, fmt)
            return parsed.replace(tzinfo=timezone.utc)
        except ValueError:
            continue

    return None


def extract_published_at_from_html(html_text: str) -> Optional[str]:
    text = clean_text(re.sub(r"<[^>]+>", " ", html_text))
    if not text:
        return None

    dmy_match = BODY_DATE_DMY_PATTERN.search(text)
    if dmy_match:
        day = int(dmy_match.group(1))
        month = MONTH_TO_NUMBER.get(dmy_match.group(2).lower())
        year = int(dmy_match.group(3))
        if month:
            try:
                return datetime(year, month, day, tzinfo=timezone.utc).isoformat()
            except ValueError:
                pass

    mdy_match = BODY_DATE_MDY_PATTERN.search(text)
    if mdy_match:
        month = MONTH_TO_NUMBER.get(mdy_match.group(1).lower())
        day = int(mdy_match.group(2))
        year = int(mdy_match.group(3))
        if month:
            try:
                return datetime(year, month, day, tzinfo=timezone.utc).isoformat()
            except ValueError:
                pass

    return None


def is_event_like_listing(text: str) -> bool:
    normalized = clean_text(text).lower()
    if not normalized:
        return False

    if any(keyword in normalized for keyword in EVENT_KEYWORDS):
        return True
    if EVENT_AGE_PATTERN.search(normalized):
        return True
    if EVENT_DAY_PATTERN.search(normalized):
        return True
    if EVENT_TIME_PATTERN.search(normalized) and " at " in normalized:
        return True
    return False


def is_valid_cover_image(url: Optional[str]) -> bool:
    if not url:
        return False
    lowered = url.lower()
    if lowered.startswith("data:image"):
        return False
    return not any(marker in lowered for marker in INVALID_COVER_IMAGE_MARKERS)


def clean_description(value: Optional[str], max_chars: int = 220) -> Optional[str]:
    return _clean_description(value, max_chars=max_chars)


def extract_first_valid_image(base_url: str, html_text: str) -> Optional[str]:
    parser = _ImageParser(base_url)
    parser.feed(html_text)
    for image in parser.images:
        if is_valid_cover_image(image):
            return image
    return None


def extract_description_from_html(html_text: str, max_chars: int = 220) -> Optional[str]:
    paragraphs = re.findall(r"<p[^>]*>(.*?)</p>", html_text, flags=re.IGNORECASE | re.DOTALL)
    candidates: List[str] = []
    for paragraph in paragraphs:
        cleaned = clean_text(re.sub(r"<[^>]+>", " ", paragraph))
        if len(cleaned) < 40:
            continue
        lower = cleaned.lower()
        if "cookie" in lower or "javascript" in lower:
            continue
        candidates.append(cleaned)

    if not candidates:
        return None

    return _clean_description(candidates[0], max_chars=max_chars)


def _is_reasonable_link_text(text: str) -> bool:
    lowered = clean_text(text).lower()
    if len(lowered) < 3 or len(lowered) > 220:
        return False
    return lowered not in GENERIC_LINK_TEXT


def _dedupe_links(links: Iterable[Tuple[str, str]], limit: int) -> List[Tuple[str, str]]:
    seen: set[str] = set()
    deduped: List[Tuple[str, str]] = []
    for href, text in links:
        if href in seen:
            continue
        seen.add(href)
        deduped.append((href, text))
        if len(deduped) >= limit:
            break
    return deduped


def _dedupe_listing_entries(entries: Iterable[ListingEntry], limit: int) -> List[ListingEntry]:
    seen: set[str] = set()
    deduped: List[ListingEntry] = []
    for entry in entries:
        if entry.href in seen:
            continue
        seen.add(entry.href)
        deduped.append(entry)
        if len(deduped) >= limit:
            break
    return deduped


def _clean_title(value: Optional[str]) -> Optional[str]:
    if not value:
        return None
    title = clean_text(value)
    for separator in (" | ", " – ", " — "):
        if separator not in title:
            continue
        left, right = title.split(separator, 1)
        if any(token in right.lower() for token in SITE_NAME_MARKERS):
            return clean_text(left)
    return title or None


def _clean_description(value: Optional[str], max_chars: int = 220) -> Optional[str]:
    if not value:
        return None
    description = clean_text(re.sub(r"<[^>]+>", " ", value))
    if len(description) <= max_chars:
        return description

    truncated = description[:max_chars].rstrip()
    if " " in truncated:
        truncated = truncated.rsplit(" ", 1)[0]
    return f"{truncated}…"


def _first_valid_cover_image(candidates: Iterable[Optional[str]], base_url: str) -> Optional[str]:
    for candidate in candidates:
        if not candidate:
            continue
        absolute = urljoin(base_url, clean_text(candidate))
        if is_valid_cover_image(absolute):
            return absolute
    return None


def _extract_json_ld_product(scripts: List[str], base_url: str) -> Dict[str, str]:
    for script in scripts:
        try:
            payload = json.loads(script)
        except json.JSONDecodeError:
            continue

        for node in _walk_json_nodes(payload):
            node_types = _normalize_types(node.get("@type"))
            if "product" not in node_types:
                continue

            name = _coerce_text(node.get("name"))
            description = _coerce_text(node.get("description"))
            image = _coerce_image(node.get("image"), base_url=base_url)
            artist = _extract_artist_from_json_ld(node)
            published_at = _coerce_text(node.get("releaseDate") or node.get("datePublished"))

            if any([name, description, image, artist, published_at]):
                return {
                    "name": name or "",
                    "description": description or "",
                    "image": image or "",
                    "artist": artist or "",
                    "publishedAt": published_at or "",
                }
    return {}


def _walk_json_nodes(payload: Any) -> Iterable[Dict[str, Any]]:
    if isinstance(payload, dict):
        yield payload
        for value in payload.values():
            yield from _walk_json_nodes(value)
        return
    if isinstance(payload, list):
        for value in payload:
            yield from _walk_json_nodes(value)


def _normalize_types(value: Any) -> List[str]:
    if isinstance(value, str):
        return [value.lower()]
    if isinstance(value, list):
        return [item.lower() for item in value if isinstance(item, str)]
    return []


def _coerce_text(value: Any) -> Optional[str]:
    if isinstance(value, str):
        cleaned = clean_text(value)
        return cleaned or None
    return None


def _coerce_image(value: Any, base_url: str) -> Optional[str]:
    candidates: List[str] = []
    if isinstance(value, str):
        candidates.append(value)
    elif isinstance(value, list):
        for item in value:
            if isinstance(item, str):
                candidates.append(item)
            elif isinstance(item, dict) and isinstance(item.get("url"), str):
                candidates.append(item["url"])
    elif isinstance(value, dict):
        if isinstance(value.get("url"), str):
            candidates.append(value["url"])

    return _first_valid_cover_image(candidates, base_url=base_url)


def _extract_artist_from_json_ld(node: Dict[str, Any]) -> Optional[str]:
    for key in ("byArtist", "artist", "brand"):
        value = node.get(key)
        if isinstance(value, str):
            cleaned = clean_text(value)
            if cleaned:
                return cleaned
        if isinstance(value, dict):
            name = value.get("name")
            if isinstance(name, str):
                cleaned = clean_text(name)
                if cleaned:
                    return cleaned
        if isinstance(value, list):
            for item in value:
                if isinstance(item, str):
                    cleaned = clean_text(item)
                    if cleaned:
                        return cleaned
                if isinstance(item, dict) and isinstance(item.get("name"), str):
                    cleaned = clean_text(item["name"])
                    if cleaned:
                        return cleaned
    return None
