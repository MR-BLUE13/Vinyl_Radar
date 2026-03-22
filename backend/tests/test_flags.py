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

    def test_new_expires(self):
        now = datetime.now(timezone.utc)
        first_seen = now - timedelta(hours=73)

        flags = classify_flags("limited edition", first_seen_at=first_seen, now=now)

        self.assertNotIn("NEW", flags)
        self.assertIn("LIMITED", flags)


if __name__ == "__main__":
    unittest.main()
