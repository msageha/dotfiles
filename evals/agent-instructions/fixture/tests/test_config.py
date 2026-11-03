import unittest

from app.config import load_config


class LoadConfigTest(unittest.TestCase):
    def test_defaults(self):
        self.assertEqual(load_config(), {"timeout": 10, "retries": 3})


if __name__ == "__main__":
    unittest.main()
