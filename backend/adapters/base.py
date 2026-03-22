from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import List

from ..models import RawRelease


class SourceAdapter:
    source: str
    store_id: str
    entry_url: str

    def fetch_latest(self, now: datetime) -> List[RawRelease]:
        raise NotImplementedError


@dataclass
class AdapterResult:
    source: str
    releases: List[RawRelease]
    error: str = ""
