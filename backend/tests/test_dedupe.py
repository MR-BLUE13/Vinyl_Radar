from datetime import datetime, timezone, timedelta
import unittest

from backend.dedupe import dedupe_within_store
from backend.models import Release


class DedupeTests(unittest.TestCase):
    def test_dedupe_within_store(self):
        now = datetime.now(timezone.utc)

        old = Release(
            id="1",
            artist="A",
            title="T",
            coverImageURL=None,
            sourceItemURL=None,
            sourceItemKey="k1",
            storeID="store_blood_records",
            publishedAt=now - timedelta(minutes=10),
            flags=["LIMITED"],
        )
        new = Release(
            id="2",
            artist="A",
            title="T",
            coverImageURL=None,
            sourceItemURL=None,
            sourceItemKey="k1",
            storeID="store_blood_records",
            publishedAt=now - timedelta(minutes=1),
            flags=["LIMITED"],
        )
        cross_store = Release(
            id="3",
            artist="A",
            title="T",
            coverImageURL=None,
            sourceItemURL=None,
            sourceItemKey="k1",
            storeID="store_bad_world",
            publishedAt=now - timedelta(minutes=2),
            flags=["LIMITED"],
        )

        out = dedupe_within_store([old, new, cross_store])
        ids = {item.id for item in out}

        self.assertIn("2", ids)
        self.assertIn("3", ids)
        self.assertNotIn("1", ids)


if __name__ == "__main__":
    unittest.main()
