import unittest
from datetime import datetime, timezone

import backend.adapters.banquet_records as banquet_module
from backend.adapters.banquet_records import BanquetRecordsAdapter
from backend.adapters.html_utils import ListingEntry, ProductMetadata


class BanquetAdapterTests(unittest.TestCase):
    def test_partial_endpoint_failure_still_returns_releases(self):
        class _ProbeBanquet(BanquetRecordsAdapter):
            def _fetch_listing_entries(self, url: str, endpoint_key: str):
                if endpoint_key == "home":
                    self.add_warning("banquet_home_fetch_failed:TimeoutError")
                    return []
                return [
                    ListingEntry(
                        href="https://www.banquetrecords.com/conan-gray/wishbone/123",
                        text="Conan Gray - Wishbone",
                        image_url="https://cdn.example.com/wishbone.jpg",
                    )
                ]

        adapter = _ProbeBanquet()
        # Patch metadata fetch in a controlled way via monkey method call pattern.
        # The production code calls module-level _safe_fetch_metadata.
        # Here we keep behavior by relying on entry image and text split.
        releases = adapter.fetch_latest(now=datetime.now(timezone.utc))

        self.assertEqual(len(releases), 1)
        self.assertEqual(releases[0].artist, "Conan Gray")
        self.assertEqual(releases[0].cover_image_url, "https://cdn.example.com/wishbone.jpg")
        warnings = adapter.pop_warnings()
        self.assertIn("banquet_home_fetch_failed:TimeoutError", warnings)

    def test_banquet_ignores_store_like_meta_artist(self):
        class _ProbeBanquet(BanquetRecordsAdapter):
            def _fetch_listing_entries(self, url: str, endpoint_key: str):
                return [
                    ListingEntry(
                        href="https://www.banquetrecords.com/conan-gray/wishbone/123",
                        text="Conan Gray - Wishbone",
                        image_url="https://cdn.example.com/wishbone.jpg",
                    )
                ]

        original = banquet_module._safe_fetch_metadata
        banquet_module._safe_fetch_metadata = lambda _url: ProductMetadata(artist="Banquet Records", title="Wishbone")
        try:
            releases = _ProbeBanquet().fetch_latest(now=datetime.now(timezone.utc))
        finally:
            banquet_module._safe_fetch_metadata = original

        self.assertEqual(len(releases), 1)
        self.assertEqual(releases[0].artist, "Conan Gray")
        self.assertEqual(releases[0].title, "Wishbone")

    def test_banquet_filters_event_entries(self):
        class _ProbeBanquet(BanquetRecordsAdapter):
            def _fetch_listing_entries(self, url: str, endpoint_key: str):
                return [
                    ListingEntry(
                        href="https://www.banquetrecords.com/scouting-for-girls/circuit-700pm/SFG300326",
                        text="Friday 27th March at Circuit, 6:00pm (14+)",
                        image_url="https://cdn.example.com/event.jpg",
                    ),
                    ListingEntry(
                        href="https://www.banquetrecords.com/arlo-parks/ambiguous-desire/TRANS930PS",
                        text="Arlo Parks - Ambiguous Desire",
                        image_url="https://cdn.example.com/arlo.jpg",
                    ),
                ]

        original = banquet_module._safe_fetch_metadata
        banquet_module._safe_fetch_metadata = lambda _url: None
        try:
            releases = _ProbeBanquet().fetch_latest(now=datetime.now(timezone.utc))
        finally:
            banquet_module._safe_fetch_metadata = original

        self.assertEqual(len(releases), 1)
        self.assertEqual(releases[0].artist, "Arlo Parks")
        self.assertEqual(releases[0].title, "Ambiguous Desire")


if __name__ == "__main__":
    unittest.main()
