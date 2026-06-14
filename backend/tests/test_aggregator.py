from datetime import datetime, timezone
from pathlib import Path
import tempfile
import unittest

from backend.aggregator import FeedAggregator
from backend.adapters.base import SourceAdapter
from backend.models import RawRelease, Release
from backend.storage import FeedState, JsonStore


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
                description="Real product description",
                published_at=now,
            )
        ]


class AggregatorTests(unittest.TestCase):
    def test_default_adapters_excludes_rough_trade(self):
        with tempfile.TemporaryDirectory() as tmp:
            store = JsonStore(Path(tmp))
            aggregator = FeedAggregator(store=store)
            sources = [adapter.source for adapter in aggregator.adapters]
            self.assertNotIn("rough_trade_us", sources)

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
            self.assertEqual(snap["releases"][0]["description"], "Real product description")
            self.assertEqual(snap["releases"][0]["publishedAtSource"], "source")
            self.assertIn("refreshMeta", snap)
            self.assertIn("perSource", snap["refreshMeta"])

    def test_empty_parse_failure_keeps_existing_store_data(self):
        class _EmptyAdapter(SourceAdapter):
            source = "bad_world"
            store_id = "store_bad_world"
            entry_url = "http://example.com"

            def fetch_latest(self, now):
                return []

        with tempfile.TemporaryDirectory() as tmp:
            store = JsonStore(Path(tmp))
            existing_release = Release(
                id="existing-bad-world",
                artist="Artist",
                title="Title",
                coverImageURL="https://cdn.example.com/cover.jpg",
                sourceItemURL="https://bad-world.co.uk/products/title",
                sourceItemKey="https://bad-world.co.uk/products/title",
                storeID="store_bad_world",
                publishedAt=datetime.now(timezone.utc),
                publishedAtSource="source",
                flags=["NEW"],
                description="Existing",
            )
            store.save_snapshot(
                generated_at="2026-03-25T00:00:00Z",
                releases=[existing_release],
                refresh_meta={
                    "generatedAt": "2026-03-25T00:00:00Z",
                    "perSource": {"bad_world": 1},
                    "failedSources": {},
                    "warnings": [],
                },
            )

            aggregator = FeedAggregator(store=store, adapters=[_EmptyAdapter()])
            metrics = aggregator.refresh()
            snap = aggregator.get_snapshot()

            self.assertEqual(metrics.total, 1)
            self.assertIn("bad_world_empty_parse_failure", metrics.warnings)
            self.assertEqual(snap["releases"][0]["id"], "existing-bad-world")

    def test_missing_raw_published_at_falls_back_to_first_seen(self):
        class _NoPublishedAdapter(SourceAdapter):
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
                        title="Title",
                        source_item_url="http://example.com/item-1",
                        cover_image_url=None,
                        published_at=None,
                    )
                ]

        with tempfile.TemporaryDirectory() as tmp:
            store = JsonStore(Path(tmp))
            state = FeedState(first_seen={
                "store_blood_records::item-1": "2024-01-02T03:04:05Z"
            })
            store.save_state(state)

            aggregator = FeedAggregator(store=store, adapters=[_NoPublishedAdapter()])
            aggregator.refresh()
            snapshot = aggregator.get_snapshot()

            self.assertEqual(
                snapshot["releases"][0]["publishedAt"],
                "2024-01-02T03:04:05Z"
            )
            self.assertEqual(snapshot["releases"][0]["publishedAtSource"], "first_seen")

    def test_refresh_meta_contains_missing_publish_time_warning(self):
        class _NoPublishedAdapter(SourceAdapter):
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
                        title="Title",
                        source_item_url="http://example.com/item-1",
                        cover_image_url=None,
                        published_at=None,
                    )
                ]

        with tempfile.TemporaryDirectory() as tmp:
            store = JsonStore(Path(tmp))
            aggregator = FeedAggregator(store=store, adapters=[_NoPublishedAdapter()])

            snapshot = aggregator.get_snapshot()
            warnings = snapshot["refreshMeta"]["warnings"]
            self.assertIn("missing_source_publish_time:blood_records:1", warnings)


if __name__ == "__main__":
    unittest.main()
