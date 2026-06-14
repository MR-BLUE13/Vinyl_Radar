from datetime import datetime, timezone, timedelta
import unittest

from backend.flags import classify_flags


class FlagTests(unittest.TestCase):
    def test_keywords_and_new(self):
        now = datetime.now(timezone.utc)
        first_seen = now - timedelta(hours=2)

        flags = classify_flags(
            "Store Exclusive Limited Marble Edition 500 copies",
            first_seen_at=first_seen,
            now=now,
        )

        self.assertIn("NEW", flags)
        self.assertIn("EXCLUSIVE", flags)
        self.assertIn("LIMITED", flags)
        self.assertIn("COLORED", flags)

    def test_signed_keywords(self):
        now = datetime.now(timezone.utc)
        first_seen = now - timedelta(hours=1)

        flags = classify_flags(
            "Personally Signed edition with hand-signed print",
            first_seen_at=first_seen,
            now=now,
        )

        self.assertIn("SIGNED", flags)

    def test_signed_keywords_from_description_text(self):
        now = datetime.now(timezone.utc)
        first_seen = now - timedelta(hours=1)

        flags = classify_flags(
            "Collector release includes autographed insert and signed print",
            first_seen_at=first_seen,
            now=now,
        )

        self.assertIn("SIGNED", flags)

    def test_new_expires(self):
        now = datetime.now(timezone.utc)
        first_seen = now - timedelta(hours=73)

        flags = classify_flags("limited edition", first_seen_at=first_seen, now=now)

        self.assertNotIn("NEW", flags)
        self.assertIn("LIMITED", flags)

    def test_exclusive_inferred_for_blood_colored(self):
        now = datetime.now(timezone.utc)
        first_seen = now - timedelta(hours=1)

        flags = classify_flags(
            "Special splatter vinyl pressing",
            first_seen_at=first_seen,
            now=now,
            source="blood_records",
        )

        self.assertIn("COLORED", flags)
        self.assertIn("EXCLUSIVE", flags)

    def test_exclusive_inferred_for_bad_world_colored(self):
        now = datetime.now(timezone.utc)
        first_seen = now - timedelta(hours=1)

        flags = classify_flags(
            "Limited marble edition",
            first_seen_at=first_seen,
            now=now,
            source="bad_world",
        )

        self.assertIn("COLORED", flags)
        self.assertIn("EXCLUSIVE", flags)

    def test_exclusive_inferred_for_blood_even_without_colored_keywords(self):
        now = datetime.now(timezone.utc)
        first_seen = now - timedelta(hours=1)

        flags = classify_flags(
            "Standard black pressing",
            first_seen_at=first_seen,
            now=now,
            source="blood_records",
        )

        self.assertIn("EXCLUSIVE", flags)

    def test_exclusive_inferred_for_bad_world_even_without_colored_keywords(self):
        now = datetime.now(timezone.utc)
        first_seen = now - timedelta(hours=1)

        flags = classify_flags(
            "Standard black pressing",
            first_seen_at=first_seen,
            now=now,
            source="bad_world",
        )

        self.assertIn("EXCLUSIVE", flags)


if __name__ == "__main__":
    unittest.main()
