import unittest
from datetime import datetime, timezone
from urllib.error import HTTPError

import backend.adapters.rough_trade_us as rough_trade_module
from backend.adapters.html_utils import ProductMetadata
from backend.adapters.rough_trade_us import RoughTradeUSAdapter


class RoughTradeUSAdapterTests(unittest.TestCase):
    def test_rough_trade_adapter_returns_non_empty(self):
        adapter = RoughTradeUSAdapter()

        original_fetch_html = rough_trade_module.fetch_html
        original_extract_entries = rough_trade_module.extract_shopify_product_entries
        original_extract_metadata = rough_trade_module.extract_product_metadata
        try:
            def fake_fetch_html(url: str, timeout: int = 4, headers=None):  # noqa: ARG001
                if "/products/" in url:
                    return "<html><head></head><body>product page</body></html>"
                return "<html><body>listing page</body></html>"

            def fake_extract_entries(base_url: str, html_text: str, limit: int = 30):  # noqa: ARG001
                if "new-this-week" in base_url:
                    return [("https://www.roughtrade.com/us/products/arlo-parks-my-soft-machine", "Arlo Parks - My Soft Machine [Personally Signed]")]
                return []

            def fake_extract_metadata(base_url: str, html_text: str):  # noqa: ARG001
                return ProductMetadata(
                    title="Arlo Parks - My Soft Machine [Personally Signed]",
                    artist="Arlo Parks",
                    cover_image_url="https://cdn.example.com/cover.jpg",
                    description="Personally signed edition",
                    published_at=datetime(2026, 3, 20, tzinfo=timezone.utc),
                )

            rough_trade_module.fetch_html = fake_fetch_html
            rough_trade_module.extract_shopify_product_entries = fake_extract_entries
            rough_trade_module.extract_product_metadata = fake_extract_metadata

            releases = adapter.fetch_latest(now=datetime.now(timezone.utc))
        finally:
            rough_trade_module.fetch_html = original_fetch_html
            rough_trade_module.extract_shopify_product_entries = original_extract_entries
            rough_trade_module.extract_product_metadata = original_extract_metadata

        self.assertEqual(len(releases), 1)
        self.assertEqual(releases[0].artist, "Arlo Parks")
        self.assertTrue(releases[0].signed_by_heuristic)

    def test_rough_trade_filters_non_vinyl_entries(self):
        adapter = RoughTradeUSAdapter()

        original_fetch_html = rough_trade_module.fetch_html
        original_extract_entries = rough_trade_module.extract_shopify_product_entries
        original_extract_metadata = rough_trade_module.extract_product_metadata
        try:
            def fake_fetch_html(url: str, timeout: int = 4, headers=None):  # noqa: ARG001
                if "/products/" in url:
                    return "<html><head></head><body>product page</body></html>"
                return "<html><body>listing page</body></html>"

            def fake_extract_entries(base_url: str, html_text: str, limit: int = 30):  # noqa: ARG001
                if "new-this-week" in base_url:
                    return [
                        ("https://www.roughtrade.com/us/products/live-show-ticket", "Live Show Ticket"),
                        ("https://www.roughtrade.com/us/products/arlo-parks-my-soft-machine", "Arlo Parks - My Soft Machine"),
                    ]
                return []

            def fake_extract_metadata(base_url: str, html_text: str):  # noqa: ARG001
                if "live-show-ticket" in base_url:
                    return ProductMetadata(
                        title="Live Show Ticket",
                        description="Event ticket",
                    )
                return ProductMetadata(
                    title="Arlo Parks - My Soft Machine",
                    artist="Arlo Parks",
                    cover_image_url="https://cdn.example.com/cover.jpg",
                    description="Vinyl pressing",
                    published_at=datetime(2026, 3, 20, tzinfo=timezone.utc),
                )

            rough_trade_module.fetch_html = fake_fetch_html
            rough_trade_module.extract_shopify_product_entries = fake_extract_entries
            rough_trade_module.extract_product_metadata = fake_extract_metadata

            releases = adapter.fetch_latest(now=datetime.now(timezone.utc))
        finally:
            rough_trade_module.fetch_html = original_fetch_html
            rough_trade_module.extract_shopify_product_entries = original_extract_entries
            rough_trade_module.extract_product_metadata = original_extract_metadata

        self.assertEqual(len(releases), 1)
        self.assertIn("Arlo Parks", releases[0].artist)

    def test_rough_trade_uses_json_ld_itemlist_fallback(self):
        adapter = RoughTradeUSAdapter()

        original_fetch_html = rough_trade_module.fetch_html
        original_extract_entries = rough_trade_module.extract_shopify_product_entries
        original_extract_metadata = rough_trade_module.extract_product_metadata
        try:
            def fake_fetch_html(url: str, timeout: int = 4, headers=None):  # noqa: ARG001
                if "/products/" in url:
                    return "<html><head></head><body>product page</body></html>"
                return """
                <html><head>
                <script type="application/ld+json">
                {
                  "@context":"https://schema.org",
                  "@type":"ItemList",
                  "itemListElement":[
                    {"@type":"ListItem","position":1,"item":{"@type":"Product","url":"https://www.roughtrade.com/us/products/kim-gordon-the-collective","name":"Kim Gordon - The Collective"}}
                  ]
                }
                </script>
                </head><body></body></html>
                """

            def fake_extract_entries(base_url: str, html_text: str, limit: int = 30):  # noqa: ARG001
                return []

            def fake_extract_metadata(base_url: str, html_text: str):  # noqa: ARG001
                return ProductMetadata(
                    title="Kim Gordon - The Collective",
                    artist="Kim Gordon",
                    cover_image_url="https://cdn.example.com/kim.jpg",
                    description="Limited vinyl pressing",
                    published_at=datetime(2026, 3, 20, tzinfo=timezone.utc),
                )

            rough_trade_module.fetch_html = fake_fetch_html
            rough_trade_module.extract_shopify_product_entries = fake_extract_entries
            rough_trade_module.extract_product_metadata = fake_extract_metadata

            releases = adapter.fetch_latest(now=datetime.now(timezone.utc))
        finally:
            rough_trade_module.fetch_html = original_fetch_html
            rough_trade_module.extract_shopify_product_entries = original_extract_entries
            rough_trade_module.extract_product_metadata = original_extract_metadata

        self.assertEqual(len(releases), 1)
        self.assertEqual(releases[0].artist, "Kim Gordon")

    def test_rough_trade_marks_blocked_warning(self):
        adapter = RoughTradeUSAdapter()

        original_fetch_html = rough_trade_module.fetch_html
        original_extract_entries = rough_trade_module.extract_shopify_product_entries
        try:
            def fake_fetch_html(url: str, timeout: int = 4, headers=None):  # noqa: ARG001
                raise HTTPError(url, 403, "Forbidden", hdrs=None, fp=None)

            def fake_extract_entries(base_url: str, html_text: str, limit: int = 30):  # noqa: ARG001
                return []

            rough_trade_module.fetch_html = fake_fetch_html
            rough_trade_module.extract_shopify_product_entries = fake_extract_entries

            with self.assertRaisesRegex(RuntimeError, "rough_trade_us_no_entries"):
                adapter.fetch_latest(now=datetime.now(timezone.utc))

            warnings = adapter.pop_warnings()
        finally:
            rough_trade_module.fetch_html = original_fetch_html
            rough_trade_module.extract_shopify_product_entries = original_extract_entries

        self.assertTrue(any("rough_trade_us_blocked_or_403" in warning for warning in warnings))


if __name__ == "__main__":
    unittest.main()
