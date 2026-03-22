from datetime import datetime, timezone
from pathlib import Path
import tempfile
import unittest

from backend.aggregator import FeedAggregator
from backend.adapters.base import SourceAdapter
from backend.models import RawRelease
from backend.storage import JsonStore


class _FakeAdapter(SourceAdapter):
    source = "blood_records"
    store_id = "store_blood_records"
    entry_url = "http://example.com"

    def fetch_latest(self, now):
        return [
            RawRelease(
                source=self.source,
                store_id=self.store_id,
                source_item_key="item-1",
                artist="Artist",
                title="Exclusive Limited Marble",
                source_item_url="http://example.com/item-1",
                cover_image_url=None,
                published_at=now,
            )
        ]


class AggregatorTests(unittest.TestCase):
    def test_refresh_writes_snapshot(self):
        with tempfile.TemporaryDirectory() as tmp:
            store = JsonStore(Path(tmp))
            aggregator = FeedAggregator(store=store, adapters=[_FakeAdapter()])

            metrics = aggregator.refresh()
            snap = aggregator.get_snapshot()

            self.assertEqual(metrics.total, 1)
            self.assertEqual(len(snap["releases"]), 1)
            self.assertEqual(snap["releases"][0]["storeID"], "store_blood_records")
            self.assertIn("NEW", snap["releases"][0]["flags"])


if __name__ == "__main__":
    unittest.main()
