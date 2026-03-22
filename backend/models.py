from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from hashlib import sha1
from typing import List, Optional


ISO_FMT = "%Y-%m-%dT%H:%M:%SZ"


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def to_iso8601(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).strftime(ISO_FMT)


def parse_iso8601(value: str) -> datetime:
    return datetime.strptime(value, ISO_FMT).replace(tzinfo=timezone.utc)


@dataclass(frozen=True)
class RawRelease:
    source: str
    store_id: str
    source_item_key: str
    artist: str
    title: str
    source_item_url: str
    cover_image_url: Optional[str]
    published_at: Optional[datetime] = None
    subtitle: Optional[str] = None


@dataclass(frozen=True)
class Release:
    id: str
    artist: str
    title: str
    coverImageURL: Optional[str]
    sourceItemURL: Optional[str]
    sourceItemKey: str
    storeID: str
    publishedAt: datetime
    flags: List[str]

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "artist": self.artist,
            "title": self.title,
            "coverImageURL": self.coverImageURL,
            "sourceItemURL": self.sourceItemURL,
            "sourceItemKey": self.sourceItemKey,
            "storeID": self.storeID,
            "publishedAt": to_iso8601(self.publishedAt),
            "flags": self.flags,
        }

    @staticmethod
    def from_dict(payload: dict) -> "Release":
        return Release(
            id=payload["id"],
            artist=payload["artist"],
            title=payload["title"],
            coverImageURL=payload.get("coverImageURL"),
            sourceItemURL=payload.get("sourceItemURL"),
            sourceItemKey=payload["sourceItemKey"],
            storeID=payload["storeID"],
            publishedAt=parse_iso8601(payload["publishedAt"]),
            flags=list(payload.get("flags", [])),
        )


def build_release_id(source: str, source_item_key: str) -> str:
    digest = sha1(source_item_key.encode("utf-8")).hexdigest()[:12]
    return f"{source}_{digest}"
