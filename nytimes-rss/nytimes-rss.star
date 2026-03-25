"""
NYTimes RSS - Displays top headlines from the New York Times
homepage RSS feed, scrolling vertically.
"""

load("render.star", "render")
load("http.star", "http")
load("cache.star", "cache")
load("xpath.star", "xpath")
load("schema.star", "schema")

RSS_URL = "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml"
CACHE_KEY = "nytimes_rss_headlines"
CACHE_TTL = 600  # 10 minutes
MAX_HEADLINES = 5

def fetch_headlines():
    cached = cache.get(CACHE_KEY)
    if cached != None:
        headlines = cached.split("\n")
        return headlines

    resp = http.get(RSS_URL)
    if resp.status_code != 200:
        return ["Failed to load NYT feed"]

    doc = xpath.loads(resp.body())
    titles = doc.query_all("/rss/channel/item/title")

    headlines = []
    for i in range(len(titles)):
        if i >= MAX_HEADLINES:
            break
        title = titles[i].replace("&amp;", "&").replace("&apos;", "'").replace("&quot;", '"')
        if len(title) > 0:
            headlines.append(title)

    if len(headlines) == 0:
        headlines = ["No headlines found"]

    cache.set(CACHE_KEY, "\n".join(headlines), ttl_seconds = CACHE_TTL)
    return headlines

def main(config):
    headlines = fetch_headlines()
    max_count = int(config.get("max_headlines", str(MAX_HEADLINES)))

    children = [
        render.Text(
            content = "NY Times",
            font = "tom-thumb",
            color = "#888888",
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
