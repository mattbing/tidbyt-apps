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

def fetch_headlines(url):
    cache_key = "rss_v2_" + url
    cached = cache.get(cache_key)
    if cached != None:
        return cached.split("\n")

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
        title = titles[i].replace("&amp;", "&").replace("&apos;", "'").replace("&quot;", '"')
        if len(title) > 0:
            headlines.append(title)

    if len(headlines) == 0:
        headlines = ["No headlines found"]

    cache.set(cache_key, "\n".join(headlines), ttl_seconds = CACHE_TTL)
    return headlines

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
