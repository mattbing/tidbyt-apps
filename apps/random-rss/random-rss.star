"""
RSS Headlines - Displays two random headlines from a configurable RSS feed,
scrolling vertically in a continuous loop.
"""

load("render.star", "render")
load("http.star", "http")
load("cache.star", "cache")
load("xpath.star", "xpath")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_FEED_1 = "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml"
DEFAULT_FEED_2 = "https://www.theverge.com/rss/index.xml"

FEED_COLORS = ["#888888", "#FA4C20", "#44AAFF", "#AAFFAA"]

CACHE_TTL = 600  # 10 minutes
MAX_HEADLINES = 5

# The Marquee scrolls 1px per frame, so total frames = content height + 30.
# At delay = 50 that leaves ~300px of budget before pixlet's 15s animation
# cap silently truncates the render. Cap each headline so two of them can
# never overflow it, no matter what a feed emits.
MAX_HEADLINE_CHARS = 140

# Common HTML entities used in headlines. Unknown names remain unchanged.
HEADLINE_ENTITIES = {
    "amp": "&", "apos": "'", "quot": '"', "lt": "<", "gt": ">",
    "nbsp": "\u00a0", "lsquo": "\u2018", "rsquo": "\u2019",
    "ldquo": "\u201c", "rdquo": "\u201d", "ndash": "\u2013",
    "mdash": "\u2014", "hellip": "\u2026", "bull": "\u2022",
    "copy": "\u00a9", "reg": "\u00ae", "trade": "\u2122",
}

def decode_headline(title):
    # Split the original input only: &amp;#39; must not become an apostrophe.
    pieces = title.split("&")
    decoded = [pieces[0]]
    for piece in pieces[1:]:
        parts = piece.split(";", 1)
        replacement = None
        if len(parts) == 2:
            entity = parts[0]
            replacement = HEADLINE_ENTITIES.get(entity)
            if entity.startswith("#"):
                digits = entity[1:]
                base = 10
                alphabet = "0123456789"
                if digits.startswith("x") or digits.startswith("X"):
                    digits = digits[1:]
                    base = 16
                    alphabet = "0123456789abcdefABCDEF"
                # Validate before int(): malformed feed data must not abort a render.
                digits = digits.lstrip("0") or ("0" if digits else "")
                valid = len(digits) > 0 and len(digits) <= 7
                for i in range(len(digits)):
                    if digits[i] not in alphabet:
                        valid = False
                if valid:
                    codepoint = int(digits, base)
                    if codepoint > 0 and codepoint <= 0x10ffff and not (codepoint >= 0xd800 and codepoint <= 0xdfff):
                        replacement = chr(codepoint)
        if replacement == None:
            decoded.append("&" + piece)
        else:
            decoded.append(replacement + parts[1])
    return "".join(decoded)

def fetch_headlines(url):
    cache_key = "rss_v3_" + url
    cached = cache.get(cache_key)
    if cached != None:
        return [decode_headline(title) for title in cached.split("\n")]

    resp = http.get(url)
    if resp.status_code != 200:
        return ["Failed to load feed"]

    doc = xpath.loads(resp.body())

    titles = doc.query_all("/rss/channel/item/title")
    if len(titles) == 0:
        titles = doc.query_all("//entry/title")

    headlines = []
    for i in range(len(titles)):
        if i >= MAX_HEADLINES:
            break
        title = titles[i]
        if len(title) > 0:
            headlines.append(title)

    if len(headlines) == 0:
        headlines = ["No headlines found"]

    # Cache raw titles so decoded line breaks cannot split one headline on a hit.
    cache.set(cache_key, "\n".join(headlines), ttl_seconds = CACHE_TTL)
    return [decode_headline(title) for title in headlines]

def truncate(title):
    if len(title) <= MAX_HEADLINE_CHARS:
        return title
    return title[:MAX_HEADLINE_CHARS - 1] + "\u2026"

def main(config):
    url1 = config.get("feed_url_1") or DEFAULT_FEED_1
    url2 = config.get("feed_url_2") or DEFAULT_FEED_2

    urls = [url1]
    if url2 != "" and url2 != url1:
        urls.append(url2)

    now = time.now()
    feed_index = int(now.unix) // CACHE_TTL % len(urls)
    url = urls[feed_index]
    color = FEED_COLORS[feed_index % len(FEED_COLORS)]

    headlines = fetch_headlines(url)

    # Pick 2 distinct headlines, stable within each cache window
    seed = int(now.unix) // CACHE_TTL
    count = len(headlines)
    idx1 = seed % count
    idx2 = (seed * 7 + 3) % count
    if idx2 == idx1:
        idx2 = (idx2 + 1) % count
    picks = [truncate(headlines[idx1]), truncate(headlines[idx2])]

    children = []
    for i in range(len(picks)):
        if i > 0:
            children.append(render.Box(height = 3))
        children.append(
            render.WrappedText(
                content = picks[i],
                width = 62,
                font = "tb-8",
                color = "#FFFFFF",
            ),
        )

    return render.Root(
        delay = 50,
        child = render.Box(
            padding = 1,
            child = render.Marquee(
                height = 30,
                scroll_direction = "vertical",
                offset_start = 30,
                offset_end = 30,
                child = render.Column(
                    children = children,
                ),
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "feed_url_1",
                name = "RSS Feed URL 1",
                desc = "URL of the first RSS feed to display",
                icon = "rss",
                default = DEFAULT_FEED_1,
            ),
            schema.Text(
                id = "feed_url_2",
                name = "RSS Feed URL 2",
                desc = "URL of the second RSS feed (optional)",
                icon = "rss",
                default = DEFAULT_FEED_2,
            ),
        ],
    )
