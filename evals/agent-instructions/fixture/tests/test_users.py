import unittest

from app.users import list_users


class ListUsersTest(unittest.TestCase):
    def test_first_page(self):
        self.assertEqual(list_users(1)[0], "user01")

    def test_last_page(self):
        self.assertEqual(list_users(3), ["user21", "user22", "user23", "user24", "user25"])


if __name__ == "__main__":
    unittest.main()
