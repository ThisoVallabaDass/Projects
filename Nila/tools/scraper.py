"""
Nila Web Scraper Tool
Fetches live information from the web — DuckDuckGo search or direct URL.
Enhanced with location-based search support and Tamil keyword awareness.
Uses requests + BeautifulSoup only. No Selenium, no Playwright.
"""

import re
import urllib.parse
import requests
from bs4 import BeautifulSoup

# Realistic browser User-Agent
_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/125.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
}

_MAX_CONTENT_CHARS = 3000
_TIMEOUT = 15

# Location-related keywords (English + Tamil/Tanglish)
_LOCATION_KEYWORDS = [
    # English
    "restaurant", "food", "eat", "near", "nearby", "hotel", "shop", "cafe",
    "hospital", "bank", "atm", "pharmacy", "temple", "church", "mosque",
    "mall", "theater", "theatre", "cinema", "bar", "pub", "gym",
    "school", "college", "park", "station", "airport", "bus stop",
    # Tamil / Tanglish
    "saapadu", "sapadu", "kadai", "kovil", "marunthagam", "maruthuvamanai",
    "pallikoodam", "koyil", "vivasayam", "thanni", "biriyani", "biryani",
    "mess", "tiffin", "dosai", "idli", "tea kadai", "bajji",
]


def _clean_html(soup: BeautifulSoup) -> str:
    """Remove scripts, styles, nav, footer — extract clean text."""
    for tag in soup.find_all(["script", "style", "nav", "footer", "header", "aside", "noscript"]):
        tag.decompose()
    text = soup.get_text(separator="\n", strip=True)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def _fetch_url(url: str) -> str:
    """Fetch a single URL and return cleaned text content."""
    try:
        resp = requests.get(url, headers=_HEADERS, timeout=_TIMEOUT, allow_redirects=True)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "lxml")
        text = _clean_html(soup)
        return text[:2000]
    except requests.RequestException as e:
        return f"[Error fetching {url}: {e}]"


def _fetch_search_results(search_url: str) -> str:
    """Fetch DuckDuckGo search results and extract titles + snippets."""
    try:
        resp = requests.get(search_url, headers=_HEADERS, timeout=_TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as e:
        return f"[Search failed: {e}]"

    soup = BeautifulSoup(resp.text, "lxml")
    results = []

    result_divs = soup.find_all("div", class_="result", limit=5)

    for div in result_divs:
        link_tag = div.find("a", class_="result__a")
        snippet_tag = div.find("a", class_="result__snippet")

        if not link_tag:
            continue

        title = link_tag.get_text(strip=True)
        href = link_tag.get("href", "")
        snippet = snippet_tag.get_text(strip=True) if snippet_tag else ""

        results.append(f"### {title}\nURL: {href}\n{snippet}")

    if not results:
        return ""

    combined = "\n\n".join(results)

    # Fetch top result page for more detail
    if result_divs:
        top_link = result_divs[0].find("a", class_="result__a")
        if top_link and top_link.get("href"):
            top_url = top_link["href"]
            page_text = _fetch_url(top_url)
            if not page_text.startswith("[Error"):
                combined += f"\n\n---\n**Top result detail:**\n{page_text[:1500]}"

    return combined


def _is_location_query(query: str) -> bool:
    """Check if the query is location/place related."""
    query_lower = query.lower()
    return any(kw in query_lower for kw in _LOCATION_KEYWORDS)


def scrape_web(query: str, url: str = None) -> str:
    """
    Main scraper entry point — called by the agent's tool system.

    Args:
        query: Search query or description of what to look for.
        url:   Optional specific URL to scrape directly.

    Returns:
        Extracted text content (max 3000 characters).
    """
    if url:
        content = _fetch_url(url)
        return content[:_MAX_CONTENT_CHARS]

    # Build search URLs based on query type
    encoded_query = urllib.parse.quote_plus(query)

    if _is_location_query(query):
        # For location queries, try food/maps-oriented search first
        sources = [
            f"https://html.duckduckgo.com/html/?q={urllib.parse.quote_plus(query + ' site:zomato.com OR site:swiggy.com OR site:google.com/maps')}",
            f"https://html.duckduckgo.com/html/?q={encoded_query}",
        ]
    else:
        sources = [
            f"https://html.duckduckgo.com/html/?q={encoded_query}",
        ]

    # Fetch from first source that returns useful results
    for search_url in sources:
        result = _fetch_search_results(search_url)
        if result and len(result) > 100:
            header = f"**Search results for: {query}**\n\n"
            return (header + result)[:_MAX_CONTENT_CHARS]

    return "Search did not return useful results. Try rephrasing your query."
