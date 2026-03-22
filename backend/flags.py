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


def _contains_any(text: str, words: tuple) -> bool:
    return any(word in text for word in words)


def classify_flags(text: str, first_seen_at: datetime, now: datetime) -> List[str]:
    normalized = text.lower()
    flags: List[str] = []

    if now - first_seen_at <= timedelta(hours=72):
        flags.append("NEW")

    if _contains_any(normalized, EXCLUSIVE_KEYWORDS):
        flags.append("EXCLUSIVE")

    if _contains_any(normalized, LIMITED_KEYWORDS):
        flags.append("LIMITED")

    if _contains_any(normalized, COLORED_KEYWORDS):
        flags.append("COLORED")

    return flags
