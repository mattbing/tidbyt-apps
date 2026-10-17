"""Offline regression tests. Run: python3 -m unittest discover -s apps/random-rss -v.

Install starlark-go==1.0.1 for the native Starlark checks (test-only dependency).
The integration harness executes the unchanged app body as Python with SDK fakes;
the decoder is also executed by Go Starlark, without translation or reimplementation.
"""
import json
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import Mock

from starlark_go import Starlark

SOURCE_PATH = Path(__file__).with_name("random-rss.star")
# Pixlet load statements are replaced by injected, offline module fakes only.
SOURCE = "\n".join(
    line for line in SOURCE_PATH.read_text().splitlines()
    if not line.startswith("load(")
)
CASES = [
    ("decimal apostrophe", "Matt&#39;s headline", "Matt's headline"),
    ("decimal quotes", "&#34;Hello&#34; &#38; goodbye", '"Hello" & goodbye'),
    ("hex apostrophe", "Matt&#x27;s", "Matt's"),
    ("uppercase hex", "&#X2019; &#x1F680;", "’ 🚀"),
    ("decimal unicode", "&#8217; &#128640;", "’ 🚀"),
    ("named basics", "&quot;A&amp;B&apos;s&quot; &lt;news&gt;", '"A&B\'s" <news>'),
    ("named punctuation", "&lsquo;one&rsquo; &ldquo;two&rdquo;&mdash;&ndash;&hellip;", "‘one’ “two”—–…"),
    ("other common names", "&nbsp;&bull;&copy;&reg;&trade;", "\u00a0•©®™"),
    ("normal text", "Normal café — news & updates", "Normal café — news & updates"),
    ("empty", "", ""),
    ("unknown", "&unknown; &AMP;", "&unknown; &AMP;"),
    ("malformed", "&#xyz; &#xZZ; &#; &#x; &;", "&#xyz; &#xZZ; &#; &#x; &;"),
    ("signed numbers", "&#+39; &#-1; &#x+27;", "&#+39; &#-1; &#x+27;"),
    ("whitespace", "&# 39; &#39 ;", "&# 39; &#39 ;"),
    ("unterminated", "&#39 &amp &#x27", "&#39 &amp &#x27"),
    ("invalid scalar", "&#0; &#xD800; &#1114112;", "&#0; &#xD800; &#1114112;"),
    ("large number", "&#999999999999999999999;", "&#999999999999999999999;"),
    ("leading zeros", "&#0000039; &#x000027;", "' '"),
    ("single pass", "&amp;#39; &amp;quot; &amp;amp;", "&#39; &quot; &amp;"),
    ("adjacent references", "&#39;&#x27;&apos;", "'''"),
    ("stray ampersands", "&&amp; A&B; &", "&& A&B; &"),
    ("scalar boundary", "&#x10FFFF;", "\U0010ffff"),
    ("numeric line break", "First&#10;second", "First\nsecond"),
]


class DecoderTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.runtime = Starlark(globals={name: {} for name in (
            "render", "http", "cache", "xpath", "schema", "time"
        )})
        # Compiles the entire app in the real Go Starlark runtime.
        cls.runtime.exec(SOURCE, filename=str(SOURCE_PATH))

    def test_entities_in_starlark(self):
        for label, original, expected in CASES:
            with self.subTest(label=label):
                self.assertEqual(
                    self.runtime.eval("decode_headline(" + json.dumps(original) + ")"),
                    expected,
                )


class AppIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.store = {}
        self.cache = SimpleNamespace(
            get=Mock(side_effect=self.store.get),
            set=Mock(side_effect=lambda key, value, **kw: self.store.update({key: value})),
        )
        self.response = SimpleNamespace(status_code=200, body=lambda: "offline fixture")
        self.http = SimpleNamespace(get=Mock(return_value=self.response))
        self.queries = Mock(return_value=[])
        self.xpath = SimpleNamespace(loads=Mock(return_value=SimpleNamespace(query_all=self.queries)))
        self.app = {"cache": self.cache, "http": self.http, "xpath": self.xpath}
        exec(compile(SOURCE, str(SOURCE_PATH), "exec"), self.app)

    def test_rss_fetch_and_cache_decode_once(self):
        self.queries.return_value = [case[1] for case in CASES[:5]]
        expected = [case[2] for case in CASES[:5]]
        self.assertEqual(self.app["fetch_headlines"]("offline:rss"), expected)
        self.assertEqual(self.app["fetch_headlines"]("offline:rss"), expected)
        self.http.get.assert_called_once_with("offline:rss")
        self.queries.assert_called_once_with("/rss/channel/item/title")
        self.cache.set.assert_called_once_with("rss_v3_offline:rss", "\n".join(self.queries.return_value), ttl_seconds=600)

    def test_atom_fallback_and_unknown_references(self):
        self.queries.side_effect = [[], ["&amp;#39;", "&#xyz; &unknown;", "Plain text"]]
        self.assertEqual(self.app["fetch_headlines"]("offline:atom"), ["&#39;", "&#xyz; &unknown;", "Plain text"])
        self.assertEqual(self.app["fetch_headlines"]("offline:atom")[0], "&#39;")
        self.assertEqual(self.queries.call_args_list[1].args, ("//entry/title",))

    def test_headline_limit_and_empty_titles(self):
        self.queries.return_value = ["", "A", "B", "C", "D", "excluded"]
        self.assertEqual(self.app["fetch_headlines"]("offline:limit"), ["A", "B", "C", "D"])

    def test_empty_feed(self):
        self.assertEqual(self.app["fetch_headlines"]("offline:empty"), ["No headlines found"])

    def test_http_failure(self):
        self.response.status_code = 503
        self.assertEqual(self.app["fetch_headlines"]("offline:error"), ["Failed to load feed"])
        self.xpath.loads.assert_not_called()
        self.cache.set.assert_not_called()

    def test_decoded_line_break_does_not_split_cached_headline(self):
        self.queries.return_value = ["First&#10;second", "Other"]
        expected = ["First\nsecond", "Other"]
        self.assertEqual(self.app["fetch_headlines"]("offline:lines"), expected)
        self.assertEqual(self.app["fetch_headlines"]("offline:lines"), expected)

    def test_main_renders_decoded_headlines_from_fresh_and_cached_feed(self):
        self.queries.return_value = ["Matt&#39;s &amp; news", "&ldquo;Hi&rdquo;"]
        wrapped = Mock(side_effect=lambda **kwargs: kwargs)
        self.app["render"] = SimpleNamespace(
            WrappedText=wrapped,
            **{name: (lambda **kwargs: kwargs) for name in ("Box", "Column", "Marquee", "Root")},
        )
        self.app["time"] = SimpleNamespace(now=lambda: SimpleNamespace(unix=0))
        config = {"feed_url_1": "offline:display", "feed_url_2": "offline:display"}
        self.app["main"](config)
        self.app["main"](config)
        self.assertEqual(
            [call.kwargs["content"] for call in wrapped.call_args_list],
            ["Matt's & news", "“Hi”", "Matt's & news", "“Hi”"],
        )
        self.http.get.assert_called_once()

    def test_old_cache_namespace_is_not_used(self):
        self.store["rss_v2_offline:old"] = "stale &#39;"
        self.queries.return_value = ["Fresh&#39;s"]
        self.assertEqual(self.app["fetch_headlines"]("offline:old"), ["Fresh's"])
        self.http.get.assert_called_once()

    def test_decode_before_truncation(self):
        self.queries.return_value = ["&#39;" * 145]
        title = self.app["fetch_headlines"]("offline:long")[0]
        self.assertEqual(self.app["truncate"](title), "'" * 139 + "…")


if __name__ == "__main__":
    unittest.main()
