import unittest

from backend.adapters.html_utils import (
    extract_banquet_listing_entries,
    extract_description_from_html,
    extract_banquet_product_entries,
    extract_artist_from_description,
    extract_first_valid_image,
    extract_product_metadata,
    extract_shopify_product_entries,
    is_event_like_listing,
    is_store_like_artist,
    is_valid_cover_image,
    parse_external_datetime,
    resolve_artist_and_title,
)


class SourceAdapterParserTests(unittest.TestCase):
    def test_extract_shopify_entries_dedupes_and_filters(self):
        html = """
        <html><body>
          <a href="/products/release-1">Artist A - Record One</a>
          <a href="/collections/drops">Drops</a>
          <a href="/products/release-1">Artist A - Record One</a>
          <a href="/products/release-2">Artist B: Record Two</a>
          <a href="/products/release-3">Shop</a>
        </body></html>
        """
        entries = extract_shopify_product_entries("https://example.com", html, limit=30)
        self.assertEqual(
            entries,
            [
                ("https://example.com/products/release-1", "Artist A - Record One"),
                ("https://example.com/products/release-2", "Artist B: Record Two"),
            ],
        )

    def test_extract_banquet_entries_with_three_segment_paths(self):
        html = """
        <html><body>
          <a href="/pre-orders">Pre Orders</a>
          <a href="/charli-xcx/brat/123456">Charli XCX - Brat</a>
          <a href="/search">Search</a>
          <a href="https://www.banquetrecords.com/conan-gray/wishbone/234567">Conan Gray - Wishbone</a>
        </body></html>
        """
        entries = extract_banquet_product_entries("https://www.banquetrecords.com/pre-orders", html, limit=30)
        self.assertEqual(
            entries,
            [
                ("https://www.banquetrecords.com/charli-xcx/brat/123456", "Charli XCX - Brat"),
                ("https://www.banquetrecords.com/conan-gray/wishbone/234567", "Conan Gray - Wishbone"),
            ],
        )

    def test_extract_banquet_listing_entries_keeps_card_image(self):
        html = """
        <html><body>
          <a href="/charli-xcx/brat/123456">
            <img src="https://cdn.example.com/card-image.jpg" />
            Charli XCX - Brat
          </a>
        </body></html>
        """
        entries = extract_banquet_listing_entries("https://www.banquetrecords.com", html, limit=10)
        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0].image_url, "https://cdn.example.com/card-image.jpg")


class ProductMetadataParserTests(unittest.TestCase):
    def test_extract_metadata_prefers_json_ld(self):
        html = """
        <html><head>
          <meta property="og:title" content="OG Title | Blood Records">
          <meta property="og:description" content="OG description text">
          <meta property="og:image" content="https://cdn.example.com/og-image.jpg">
          <script type="application/ld+json">
            {
              "@context": "https://schema.org",
              "@type": "Product",
              "name": "Nala Sine - Afterlight Sessions",
              "description": "Limited colored pressing with numbered sleeve and hand-stamped insert.",
              "image": ["https://cdn.example.com/jsonld-image.jpg"],
              "brand": {"@type":"Brand","name":"Nala Sine"}
            }
          </script>
        </head><body></body></html>
        """

        metadata = extract_product_metadata("https://example.com/products/afterlight", html)
        self.assertEqual(metadata.title, "Nala Sine - Afterlight Sessions")
        self.assertEqual(metadata.artist, "Nala Sine")
        self.assertEqual(metadata.cover_image_url, "https://cdn.example.com/jsonld-image.jpg")
        self.assertIn("Limited colored pressing", metadata.description or "")

    def test_extract_metadata_uses_og_image_when_json_ld_image_invalid(self):
        html = """
        <html><head>
          <meta property="og:image" content="https://cdn.example.com/cover.jpg">
          <script type="application/ld+json">
            {"@type":"Product","name":"Artist - Title","image":"https://blood-records.co.uk/cdn/shop/t/9/assets/placeholder-vinyl.png"}
          </script>
        </head><body></body></html>
        """

        metadata = extract_product_metadata("https://example.com/products/title", html)
        self.assertEqual(metadata.cover_image_url, "https://cdn.example.com/cover.jpg")
        self.assertTrue(is_valid_cover_image(metadata.cover_image_url))

    def test_description_is_trimmed_to_short_copy(self):
        long_text = " ".join(["This is a long product description."] * 30)
        html = f"""
        <html><head>
          <meta property="og:description" content="{long_text}">
        </head></html>
        """
        metadata = extract_product_metadata("https://example.com/products/title", html)
        self.assertIsNotNone(metadata.description)
        self.assertLessEqual(len(metadata.description or ""), 221)

    def test_extract_first_valid_image_falls_back_from_body(self):
        html = """
        <html><body>
          <img src="https://blood-records.co.uk/cdn/shop/t/9/assets/placeholder-vinyl.png" />
          <img src="https://cdn.example.com/body-cover.jpg" />
        </body></html>
        """
        image = extract_first_valid_image("https://example.com", html)
        self.assertEqual(image, "https://cdn.example.com/body-cover.jpg")

    def test_extract_description_from_html_uses_paragraph_text(self):
        html = """
        <html><body>
          <p>Short.</p>
          <p>This is the first meaningful long paragraph describing the release edition in enough detail to be useful for the detail page.</p>
        </body></html>
        """
        description = extract_description_from_html(html)
        self.assertIsNotNone(description)
        self.assertIn("first meaningful long paragraph", description or "")

    def test_resolve_artist_and_title_fallback(self):
        artist, title = resolve_artist_and_title("Courtney Barnett: Creature Of Habit", None)
        self.assertEqual(artist, "Courtney Barnett")
        self.assertEqual(title, "Creature Of Habit")

    def test_store_like_artist_detection(self):
        self.assertTrue(is_store_like_artist("bad world"))
        self.assertTrue(is_store_like_artist("Banquet Records"))
        self.assertFalse(is_store_like_artist("Courtney Barnett"))

    def test_extract_artist_from_description(self):
        description = "One of our album picks, Man's Best Friend by Sabrina Carpenter comes to collectors edition vinyl."
        self.assertEqual(extract_artist_from_description(description), "Sabrina Carpenter")

    def test_event_like_listing_detection(self):
        event_text = "Friday 27th March at Circuit, 6:00pm (14+)"
        release_text = "Arlo Parks - Ambiguous Desire"
        self.assertTrue(is_event_like_listing(event_text))
        self.assertFalse(is_event_like_listing(release_text))

    def test_extract_metadata_parses_published_at_from_json_ld(self):
        html = """
        <html><head>
          <script type="application/ld+json">
            {
              "@context": "https://schema.org",
              "@type": "Product",
              "name": "Arlo Parks - My Soft Machine",
              "datePublished": "2023-05-26T00:00:00Z"
            }
          </script>
        </head></html>
        """

        metadata = extract_product_metadata("https://example.com/products/arlo", html)
        self.assertIsNotNone(metadata.published_at)
        self.assertEqual(metadata.published_at.isoformat(), "2023-05-26T00:00:00+00:00")

    def test_parse_external_datetime_handles_date_only(self):
        parsed = parse_external_datetime("2024-12-03")
        self.assertIsNotNone(parsed)
        self.assertEqual(parsed.isoformat(), "2024-12-03T00:00:00+00:00")

    def test_extract_metadata_parses_published_at_from_body_text(self):
        html = """
        <html><body>
          <div class="product-copy">
            Available from 27 March 2026.
          </div>
        </body></html>
        """

        metadata = extract_product_metadata("https://example.com/products/title", html)
        self.assertIsNotNone(metadata.published_at)
        self.assertEqual(metadata.published_at.isoformat(), "2026-03-27T00:00:00+00:00")


if __name__ == "__main__":
    unittest.main()
