import io
import os
import tempfile
import unittest
from types import SimpleNamespace
from unittest import mock

import scripts.openai_quota_guard as guard


class OpenAIQuotaGuardTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        os.environ["OPENAI_QUOTA_STATE_DIR"] = self.tempdir.name
        guard.STATE_DIR = guard.Path(self.tempdir.name)
        guard.STATE_FILE = guard.STATE_DIR / "openai_quota.json"
        if guard.STATE_FILE.exists():
            guard.STATE_FILE.unlink()

    def tearDown(self):
        self.tempdir.cleanup()
        os.environ.pop("OPENAI_QUOTA_STATE_DIR", None)

    def test_bucket_for_model(self):
        self.assertEqual(guard.bucket_for_model("gpt-5"), "tokens_250k")
        self.assertEqual(guard.bucket_for_model("gpt-5.1-codex-mini"), "tokens_2_5m")
        self.assertIsNone(guard.bucket_for_model("gpt-1"))

    def test_request_consumes_tokens_and_exposes_key(self):
        args = SimpleNamespace(model="gpt-5", tokens=100)
        status = guard.cmd_request(args)
        self.assertEqual(status, 0)
        state = guard.load_state()
        self.assertEqual(state["buckets"]["tokens_250k"], guard.DAILY_LIMITS["tokens_250k"] - 100)

    def test_request_rejects_when_over_limit(self):
        args = SimpleNamespace(model="gpt-5", tokens=guard.DAILY_LIMITS["tokens_250k"] + 1)
        status = guard.cmd_request(args)
        self.assertEqual(status, 1)

    def test_status_prints_allowlist(self):
        args = SimpleNamespace(allowlist=True)
        buf = io.StringIO()
        with unittest.mock.patch("sys.stdout", new=buf):
            status = guard.cmd_status(args)
        output = buf.getvalue()
        self.assertEqual(status, 0)
        self.assertIn("250k-token models", output)
        self.assertIn("2.5M-token models", output)


if __name__ == "__main__":
    unittest.main()
