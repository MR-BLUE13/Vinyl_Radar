from __future__ import annotations

import html
import re
from html.parser import HTMLParser
from typing import List, Optional, Tuple
from urllib.parse import urljoin


def clean_text(value: str) -> str:
    text = html.unescape(value)
    text = re.sub(r"\s+", " ", text).strip()
    return text


class LinkImageParser(HTMLParser):
    def __init__(self, base_url: str) -> None:
        super().__init__()
        self.base_url = base_url
        self.links: List[Tuple[str, str]] = []
        self.images: List[str] = []
        self._in_anchor = False
        self._anchor_href = ""
        self._anchor_chunks: List[str] = []

    def handle_starttag(self, tag: str, attrs):
        attrs_dict = dict(attrs)

        if tag == "a":
            href = attrs_dict.get("href", "")
            self._in_anchor = True
            self._anchor_href = href
            self._anchor_chunks = []

        if tag == "img":
            src = attrs_dict.get("src") or attrs_dict.get("data-src")
            if src:
                self.images.append(urljoin(self.base_url, src))

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


def extract_candidate_entries(base_url: str, html_text: str) -> List[Tuple[str, str, Optional[str]]]:
    parser = LinkImageParser(base_url)
    parser.feed(html_text)

    product_links = []
    for href, text in parser.links:
        lowered = href.lower()
        if not any(token in lowered for token in ("/products/", "/product/", "/releases/", "/drop")):
            continue
        if len(text) < 3 or len(text) > 180:
            continue
        if text.lower() in {"read more", "shop", "view all", "pre-order"}:
            continue
        product_links.append((href, text))

    # De-dup by href preserving order.
    seen = set()
    deduped: List[Tuple[str, str]] = []
    for href, text in product_links:
        if href in seen:
            continue
        seen.add(href)
        deduped.append((href, text))

    images = parser.images
    entries: List[Tuple[str, str, Optional[str]]] = []
    for index, (href, text) in enumerate(deduped[:60]):
        image_url = images[index] if index < len(images) else None
        entries.append((href, text, image_url))

    return entries
