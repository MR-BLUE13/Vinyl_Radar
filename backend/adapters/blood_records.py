from __future__ import annotations

from datetime import datetime
from typing import List
from urllib.request import Request, urlopen

from .base import SourceAdapter
from .html_utils import extract_candidate_entries
from ..models import RawRelease


class BloodRecordsAdapter(SourceAdapter):
    source = "blood_records"
    store_id = "store_blood_records"
    entry_url = "https://blood-records.co.uk/collections/drops"

    def fetch_latest(self, now: datetime) -> List[RawRelease]:
        html_text = _fetch_html(self.entry_url)
        entries = extract_candidate_entries(self.entry_url, html_text)
        releases: List[RawRelease] = []
        for href, text, image_url in entries:
            releases.append(
                RawRelease(
                    source=self.source,
                    store_id=self.store_id,
                    source_item_key=href,
                    artist=_guess_artist(text),
                    title=_guess_title(text),
                    source_item_url=href,
                    cover_image_url=image_url,
                    published_at=now,
                )
            )
        return releases


def _fetch_html(url: str) -> str:
    request = Request(
        url,
        headers={
            "User-Agent": "VinylRadarBot/1.0 (+https://example.local)",
            "Accept": "text/html,application/xhtml+xml",
        },
    )
    with urlopen(request, timeout=8) as response:
        return response.read().decode("utf-8", errors="ignore")


def _guess_artist(text: str) -> str:
    if " - " in text:
        return text.split(" - ", 1)[0].strip()
    return "Unknown Artist"


def _guess_title(text: str) -> str:
    if " - " in text:
        return text.split(" - ", 1)[1].strip()
    return text.strip()
