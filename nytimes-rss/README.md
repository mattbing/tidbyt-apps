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

## Usage

```sh
pixlet render nytimes-rss/nytimes-rss.star
pixlet serve nytimes-rss/nytimes-rss.star
```
