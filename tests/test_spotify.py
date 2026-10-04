"""Tests for the Spotify helpers: a failing lookup is reported in the log (not
silently treated as "nothing playing"), and the token generator always does a
fresh login instead of tripping over a revoked cached one."""
import logging
import os
import sys
import types
import unittest
from unittest import mock

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "python"))

import getSongInfo as gsi  # noqa: E402
import generateToken  # noqa: E402


class Revoked(Exception):
    pass


class FailingClient:
    def currently_playing(self):
        raise Revoked("error: invalid_grant, error_description: Refresh token revoked")


class PlayingClient:
    def currently_playing(self):
        return {"is_playing": True,
                "item": {"name": "Song", "artists": [{"name": "Band"}],
                         "album": {"images": [{"url": "big"}, {"url": "small"}]}}}


class GetSongInfoTest(unittest.TestCase):
    def setUp(self):
        gsi._clients.clear()
        gsi._last_logged.clear()

    def _with_client(self, client):
        return mock.patch.object(gsi, "_client", return_value=client)

    def test_playing_returns_smallest_art(self):
        with self._with_client(PlayingClient()):
            info = gsi.getSongInfo("u", "t")
        self.assertTrue(info["is_playing"])
        self.assertEqual(info["image_url"], "small")
        self.assertEqual(info["artist"], "Band")

    def test_failure_is_not_playing_and_is_logged_with_the_fix(self):
        with self._with_client(FailingClient()), \
                self.assertLogs("spotipi", level=logging.WARNING) as logs:
            info = gsi.getSongInfo("u", "t")
        self.assertFalse(info["is_playing"])
        text = "\n".join(logs.output)
        self.assertIn("Refresh token revoked", text)
        self.assertIn("generate-token.sh", text)

    def test_same_failure_is_logged_once_per_interval(self):
        with self._with_client(FailingClient()), \
                self.assertLogs("spotipi", level=logging.WARNING) as logs:
            for _ in range(20):
                gsi.getSongInfo("u", "t")
        self.assertEqual(sum("lookup failed" in line for line in logs.output), 1)


class GenerateTokenTest(unittest.TestCase):
    def test_always_does_a_fresh_login(self):
        calls = {}

        class FakeOAuth:
            def __init__(self, **kw):
                calls["init"] = kw

            def get_access_token(self, as_dict=True, check_cache=True):
                calls["check_cache"] = check_cache
                return "token"

        env = {"SPOTIPY_CLIENT_ID": "i", "SPOTIPY_CLIENT_SECRET": "s",
               "SPOTIPY_REDIRECT_URI": "http://127.0.0.1/callback"}
        with mock.patch.object(generateToken, "SpotifyOAuth", FakeOAuth), \
                mock.patch.dict(os.environ, env), \
                mock.patch.object(sys, "argv", ["generateToken.py", "someone", "/tmp/.cache-x"]), \
                mock.patch("builtins.print"):
            self.assertEqual(generateToken.main(), 0)
        self.assertIs(calls["check_cache"], False)
        self.assertEqual(calls["init"]["scope"], gsi.SCOPE)


if __name__ == "__main__":
    unittest.main()
