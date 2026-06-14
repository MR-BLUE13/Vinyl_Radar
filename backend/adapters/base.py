from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import List

from ..models import RawRelease


class SourceAdapter:
    source: str
    store_id: str
    entry_url: str
    _warnings: List[str]

    def fetch_latest(self, now: datetime) -> List[RawRelease]:
        raise NotImplementedError

    def add_warning(self, warning: str) -> None:
        if not warning:
            return
        if "_warnings" not in self.__dict__:
            self._warnings = []
        self._warnings.append(warning)

    def pop_warnings(self) -> List[str]:
        warnings = list(self.__dict__.get("_warnings", []))
        self._warnings = []
        return warnings


@dataclass
class AdapterResult:
    source: str
    releases: List[RawRelease]
    error: str = ""
