from __future__ import annotations

from typing import Dict, Iterable, List, Tuple

from .models import Release


def dedupe_within_store(releases: Iterable[Release]) -> List[Release]:
    best_by_key: Dict[Tuple[str, str], Release] = {}

    for release in releases:
        key = (release.storeID, release.sourceItemKey)
        existing = best_by_key.get(key)
        if existing is None or release.publishedAt > existing.publishedAt:
            best_by_key[key] = release

    return sorted(
        best_by_key.values(),
        key=lambda r: (r.publishedAt, _rarity_score(r.flags), r.artist.lower(), r.title.lower()),
        reverse=True,
    )


def _rarity_score(flags: List[str]) -> int:
    score = 0
    if "NEW" in flags:
        score += 8
    if "EXCLUSIVE" in flags:
        score += 4
    if "LIMITED" in flags:
        score += 2
    if "COLORED" in flags:
        score += 1
    return score
