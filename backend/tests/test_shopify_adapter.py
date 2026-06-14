import unittest
from datetime import datetime, timezone

from backend.adapters.shopify_base import ShopifyCollectionAdapter


class _TestShopifyAdapter(ShopifyCollectionAdapter):
    source = "blood_records"
    store_id = "store_blood_records"
    entry_url = "https://blood-records.co.uk/collections/drops"

    def fetch_from_html_fallback(self, now: datetime):
        return []


class ShopifyAdapterTests(unittest.TestCase):
    def test_map_product_uses_vendor_cover_description_and_stock(self):
        adapter = _TestShopifyAdapter()
        product = {
            "handle": "afterlight",
            "title": "Afterlight Sessions",
            "vendor": "Nala Sine",
            "body_html": "<p>Limited colored pressing with numbered sleeve.</p>",
            "image": {"src": "https://cdn.example.com/cover-main.jpg"},
            "variants": [
                {"available": False},
                {"available": False},
            ],
        }

        release = adapter._map_product(product=product, now=datetime.now(timezone.utc))
        self.assertIsNotNone(release)
        self.assertEqual(release.artist, "Nala Sine")
        self.assertEqual(release.title, "Afterlight Sessions")
        self.assertEqual(release.cover_image_url, "https://cdn.example.com/cover-main.jpg")
        self.assertTrue(release.is_sold_out)
        self.assertIn("Limited colored pressing", release.description or "")

    def test_map_product_falls_back_to_split_title_when_vendor_missing(self):
        adapter = _TestShopifyAdapter()
        product = {
            "handle": "charli",
            "title": "Charli XCX - Brat",
            "vendor": "",
            "images": [
                {"src": "https://cdn.example.com/cover-1.jpg"},
            ],
            "variants": [{"available": True}],
        }

        release = adapter._map_product(product=product, now=datetime.now(timezone.utc))
        self.assertIsNotNone(release)
        self.assertEqual(release.artist, "Charli XCX")
        self.assertEqual(release.title, "Brat")
        self.assertFalse(release.is_sold_out)

    def test_shopify_artist_ignores_store_vendor(self):
        adapter = _TestShopifyAdapter()
        product = {
            "handle": "cruelworld",
            "title": "Cruel World",
            "vendor": "badworldrecords",
            "body_html": "<p>Holly Humberstone returns with her highly anticipated second album, Cruel World.</p>",
            "variants": [{"available": True}],
        }

        release = adapter._map_product(product=product, now=datetime.now(timezone.utc))
        self.assertIsNotNone(release)
        self.assertEqual(release.artist, "Holly Humberstone")
        self.assertEqual(release.title, "Cruel World")

    def test_shopify_artist_from_description_conservative(self):
        adapter = _TestShopifyAdapter()
        product = {
            "handle": "mbf",
            "title": "Man's Best Friend",
            "vendor": "Bad World",
            "body_html": "<p>One of our album picks, Man's Best Friend by Sabrina Carpenter comes to collectors edition vinyl.</p>",
            "variants": [{"available": True}],
        }

        release = adapter._map_product(product=product, now=datetime.now(timezone.utc))
        self.assertIsNotNone(release)
        self.assertEqual(release.artist, "Sabrina Carpenter")
        self.assertEqual(release.title, "Man's Best Friend")

    def test_multi_endpoint_fallback_uses_first_non_empty_products_payload(self):
        class _ProbeAdapter(_TestShopifyAdapter):
            products_json_urls = [
                "https://bad-world.co.uk/collections/frontpage/products.json?limit=250",
                "https://bad-world.co.uk/collections/all/products.json?limit=250",
            ]

            def __init__(self):
                self.calls = []

            def _fetch_json_payload(self, url: str) -> str:
                self.calls.append(url)
                if "frontpage" in url:
                    return "{\"products\": []}"
                return (
                    '{"products": ['
                    '{"handle":"wishbone","title":"Conan Gray - Wishbone","vendor":"","variants":[{"available":true}]}'
                    "]}"
                )

        adapter = _ProbeAdapter()
        releases = adapter.fetch_latest(now=datetime.now(timezone.utc))

        self.assertEqual(len(adapter.calls), 2)
        self.assertEqual(len(releases), 1)
        self.assertEqual(releases[0].artist, "Conan Gray")

    def test_shopify_published_time_precedence(self):
        adapter = _TestShopifyAdapter()
        product = {
            "handle": "time-check",
            "title": "Artist - Title",
            "vendor": "",
            "published_at": "2024-06-01T10:00:00+01:00",
            "created_at": "2024-05-01T10:00:00+01:00",
            "updated_at": "2024-07-01T10:00:00+01:00",
            "variants": [{"available": True}],
        }

        release = adapter._map_product(product=product, now=datetime.now(timezone.utc))
        self.assertIsNotNone(release)
        self.assertIsNotNone(release.published_at)
        self.assertEqual(release.published_at.isoformat(), "2024-06-01T09:00:00+00:00")

    def test_shopify_published_time_supports_camel_case_keys(self):
        adapter = _TestShopifyAdapter()
        product = {
            "handle": "time-check-camel",
            "title": "Artist - Title",
            "vendor": "",
            "publishedAt": "2024-06-11T10:00:00+01:00",
            "createdAt": "2024-05-11T10:00:00+01:00",
            "updatedAt": "2024-07-11T10:00:00+01:00",
            "variants": [{"available": True}],
        }

        release = adapter._map_product(product=product, now=datetime.now(timezone.utc))
        self.assertIsNotNone(release)
        self.assertIsNotNone(release.published_at)
        self.assertEqual(release.published_at.isoformat(), "2024-06-11T09:00:00+00:00")


if __name__ == "__main__":
    unittest.main()
