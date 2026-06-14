import unittest
import inspect

from backend.app import RadarHandler


class AppRoutesTests(unittest.TestCase):
    def test_refresh_status_route_declared_in_handler(self):
        source = inspect.getsource(RadarHandler.do_GET)
        self.assertIn("/v1/radar/refresh-status", source)


if __name__ == "__main__":
    unittest.main()
