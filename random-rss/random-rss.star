"""
RSS Headlines - Displays top headlines from a randomly selected RSS feed,
scrolling vertically. Rotates between multiple news sources.
"""

load("render.star", "render")
load("http.star", "http")
load("cache.star", "cache")
load("xpath.star", "xpath")
load("schema.star", "schema")
load("time.star", "time")

RSS_FEEDS = [
    {
        "name": "NY Times",
        "url": "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml",
        "color": "#888888",
    },
    {
        "name": "The Verge",
        "url": "https://www.theverge.com/rss/index.xml",
        "color": "#FA4C20",
    },
]

CACHE_TTL = 600  # 10 minutes
MAX_HEADLINES = 5

def fetch_headlines(feed):
    cache_key = "rss_headlines_" + feed["name"]
    cached = cache.get(cache_key)
    if cached != None:
        return cached.split("\n")

    resp = http.get(feed["url"])
    if resp.status_code != 200:
        return ["Failed to load " + feed["name"] + " feed"]

    doc = xpath.loads(resp.body())

    # Try RSS 2.0 format first, then Atom format
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

def main(config):
    now = time.now()
    feed_index = int(now.unix) % len(RSS_FEEDS)
    feed = RSS_FEEDS[feed_index]

    headlines = fetch_headlines(feed)
    max_count = int(config.get("max_headlines", str(MAX_HEADLINES)))

    children = [
        render.Text(
            content = feed["name"],
            font = "tom-thumb",
            color = feed["color"],
        ),
        render.Box(height = 1),
    ]

    for i in range(len(headlines)):
        if i >= max_count:
            break
        children.append(
            render.WrappedText(
                content = headlines[i],
                width = 62,
                font = "tom-thumb",
                color = "#FFFFFF",
            ),
        )
        children.append(render.Box(height = 2))

    return render.Root(
        delay = 100,
        child = render.Box(
            padding = 1,
            child = render.Marquee(
                height = 30,
                scroll_direction = "vertical",
                offset_start = 30,
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
            schema.Dropdown(
                id = "max_headlines",
                name = "Number of Headlines",
                desc = "How many headlines to display",
                icon = "newspaper",
                default = "5",
                options = [
                    schema.Option(display = "3", value = "3"),
                    schema.Option(display = "5", value = "5"),
                    schema.Option(display = "7", value = "7"),
                ],
            ),
        ],
    )
