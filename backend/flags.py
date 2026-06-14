from __future__ import annotations

from datetime import datetime, timedelta
from typing import List

LIMITED_KEYWORDS = (
    "limited",
    "copies",
    "numbered",
)

COLORED_KEYWORDS = (
    "colored",
    "coloured",
    "splatter",
    "clear",
    "marble",
)

EXCLUSIVE_KEYWORDS = (
    "exclusive",
    "store exclusive",
)

ALWAYS_EXCLUSIVE_SOURCES = {
    "blood_records",
    "bad_world",
}

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


def _contains_any(text: str, words: tuple) -> bool:
    return any(word in text for word in words)


def classify_flags(
    text: str,
    first_seen_at: datetime,
    now: datetime,
    source: str | None = None,
) -> List[str]:
    normalized = text.lower()
    flags: List[str] = []

    if now - first_seen_at <= timedelta(hours=72):
        flags.append("NEW")

    has_exclusive_keyword = _contains_any(normalized, EXCLUSIVE_KEYWORDS)
    has_colored_keyword = _contains_any(normalized, COLORED_KEYWORDS)
    infer_exclusive_by_source = source in ALWAYS_EXCLUSIVE_SOURCES

    if has_exclusive_keyword or infer_exclusive_by_source:
        flags.append("EXCLUSIVE")

    if _contains_any(normalized, LIMITED_KEYWORDS):
        flags.append("LIMITED")

    if has_colored_keyword:
        flags.append("COLORED")

    signed_text = normalized.replace("unsigned", "")
    if _contains_any(signed_text, SIGNED_KEYWORDS):
        flags.append("SIGNED")

    return flags
