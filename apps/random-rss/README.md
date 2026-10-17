# NYTimes RSS

Displays the top headlines from the New York Times homepage RSS feed on your Tidbyt, scrolling vertically.

## What it displays

- "NY Times" header
- Top headlines from the NYT homepage, scrolling upward

## Configuration

- **Number of Headlines**: Choose 3, 5, or 7 headlines to display (default: 5)

## Data Source

Fetches from the public NYT RSS feed: `https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml`

Headlines are cached for 10 minutes to avoid excessive requests.

## Headline entity decoding

Before display, titles are decoded once, before truncation. Decimal (`&#39;`)
and hexadecimal (`&#x27;` or `&#X27;`) references to nonzero Unicode scalar values
are supported. Invalid numbers, nulls, surrogates, out-of-range code points,
unknown names, and references without a semicolon are preserved literally.

The app uses Starlark's built-in `int` and `chr`, with a small named-entity table
rather than an additional runtime dependency. Supported names are `amp`, `apos`,
`quot`, `lt`, `gt`, `nbsp`, `lsquo`, `rsquo`, `ldquo`, `rdquo`, `ndash`, `mdash`,
`hellip`, `bull`, `copy`, `reg`, and `trade`. This is not a full HTML5 parser:
names are case-sensitive and numeric references are Unicode code points, not
legacy Windows-1252 remappings. Nested references are not repeatedly decoded
(for example, `&amp;#39;` becomes `&#39;`, not an apostrophe).

### Offline regression tests

From the repository root, with Python 3 and the test-only Go Starlark binding:

```sh
python3 -m pip install starlark-go==1.0.1
python3 -m unittest discover -s apps/random-rss -v
```

Tests compile the whole app and exercise the actual decoder in Go Starlark.
A Python-compatible execution of the app body, with offline Pixlet module fakes,
also checks RSS/Atom fetching, cache hits, errors, limits, and truncation. It does
not replace a full Pixlet render test; no network feeds or device access are used.

## Usage

```sh
pixlet render nytimes-rss/nytimes-rss.star
pixlet serve nytimes-rss/nytimes-rss.star
```
