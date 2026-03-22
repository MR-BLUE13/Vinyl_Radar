from __future__ import annotations

from datetime import datetime
from typing import List

from .base import SourceAdapter
from ..models import RawRelease


class RoughTradeUSAdapter(SourceAdapter):
    """Phase-2 placeholder. Not included in v1 runtime pipeline."""

    source = "rough_trade_us"
    store_id = "store_rough_trade_us"
    entry_url = "https://www.roughtrade.com/us"

    def fetch_latest(self, now: datetime) -> List[RawRelease]:
        return []
