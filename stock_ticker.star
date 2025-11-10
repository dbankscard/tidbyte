"""
Stock Ticker App for Tidbyt
Displays current prices for a configurable list of stocks
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("schema.star", "schema")

# Default stock symbols
DEFAULT_STOCKS = "AAPL,GOOGL,MSFT,TSLA"

# Cache TTL (1 minute for more frequent updates)
CACHE_TTL = 60

# Demo mode - uses mock data for testing
DEMO_MODE = False

# Mock stock data for demo
DEMO_DATA = {
    "AAPL": {"price": 178.45, "change": 2.34, "change_pct": 1.33},
    "GOOGL": {"price": 141.20, "change": -0.85, "change_pct": -0.60},
    "MSFT": {"price": 378.91, "change": 5.12, "change_pct": 1.37},
    "TSLA": {"price": 242.84, "change": -3.22, "change_pct": -1.31},
    "AMZN": {"price": 145.73, "change": 1.89, "change_pct": 1.31},
    "NVDA": {"price": 495.22, "change": 12.45, "change_pct": 2.58},
}

def main(config):
    """Main entry point for the stock ticker app."""

    # Get stock symbols from config or use defaults
    stocks_str = config.get("stocks", DEFAULT_STOCKS)
    stocks = [s.strip() for s in stocks_str.split(",")]

    # Get Finnhub API key from config
    api_key = config.get("api_key", "")

    # Fetch stock data
    stock_data = []
    for symbol in stocks:
        data = get_stock_price(symbol, api_key)
        if data:
            stock_data.append(data)

    # If no data could be fetched, show error
    if not stock_data:
        return render.Root(
            child = render.Box(
                child = render.WrappedText(
                    content = "Unable to fetch stock data",
                    color = "#ff0000",
                )
            )
        )

    # Create display
    return render.Root(
        delay = 100,  # 100ms per frame
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 8,
                    color = "#1a1a1a",
                    child = render.Text(
                        content = "STOCKS",
                        font = "tom-thumb",
                        color = "#00ff00",
                    )
                ),
                render.Box(
                    width = 64,
                    height = 24,
                    child = render.Marquee(
                        height = 24,
                        scroll_direction = "vertical",
                        child = render.Column(
                            children = [
                                create_stock_row(stock) for stock in stock_data
                            ],
                        ),
                    ),
                ),
            ],
        ),
    )

def format_price(price):
    """Format a price to 2 decimal places."""
    # Convert to int cents then back to dollars
    cents = int(price * 100 + 0.5)  # Round
    dollars = cents // 100
    cents_remainder = cents % 100

    # Pad cents with leading zero if needed
    cents_str = str(cents_remainder)
    if cents_remainder < 10:
        cents_str = "0" + cents_str

    return "$" + str(dollars) + "." + cents_str

def format_percent(pct):
    """Format a percentage to 2 decimal places."""
    # Convert to basis points then format
    basis_points = int(abs(pct) * 100 + 0.5)  # Round
    whole = basis_points // 100
    fraction = basis_points % 100

    # Pad fraction with leading zero if needed
    fraction_str = str(fraction)
    if fraction < 10:
        fraction_str = "0" + fraction_str

    # Add sign back
    if pct < 0:
        return "-" + str(whole) + "." + fraction_str + "%"
    else:
        return str(whole) + "." + fraction_str + "%"

def create_stock_row(stock):
    """Create a display row for a single stock."""
    symbol = stock["symbol"]
    price = stock["price"]
    change = stock["change"]
    change_pct = stock["change_pct"]

    # Determine color based on change
    if change >= 0:
        color = "#00ff00"  # Green for positive
        sign = "+"
    else:
        color = "#ff0000"  # Red for negative
        sign = ""

    return render.Row(
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Text(
                content = symbol,
                font = "tb-8",
                color = "#ffffff",
            ),
            render.Column(
                cross_align = "end",
                children = [
                    render.Text(
                        content = format_price(price),
                        font = "tb-8",
                        color = "#ffffff",
                    ),
                    render.Text(
                        content = sign + format_percent(change_pct),
                        font = "tom-thumb",
                        color = color,
                    ),
                ],
            ),
        ],
    )

def get_stock_price(symbol, api_key):
    """Fetch current stock price for a symbol."""

    # Demo mode - return mock data
    if DEMO_MODE:
        demo = DEMO_DATA.get(symbol)
        if demo:
            return {
                "symbol": symbol,
                "price": demo["price"],
                "change": demo["change"],
                "change_pct": demo["change_pct"],
            }
        else:
            # Return mock data for unknown symbols
            return {
                "symbol": symbol,
                "price": 100.00,
                "change": 0.50,
                "change_pct": 0.50,
            }

    # Check cache first
    cache_key = "stock_%s" % symbol
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    # Finnhub API endpoint
    if not api_key:
        print("Error: Finnhub API key not provided")
        return None

    url = "https://finnhub.io/api/v1/quote?symbol=%s&token=%s" % (symbol, api_key)

    resp = http.get(url, ttl_seconds = CACHE_TTL)

    if resp.status_code != 200:
        print("Error fetching %s: %d" % (symbol, resp.status_code))
        return None

    data = resp.json()

    # Finnhub response format:
    # c: current price, d: change, dp: percent change, h: high, l: low, o: open, pc: previous close
    current_price = data.get("c")
    change = data.get("d")
    change_pct = data.get("dp")

    if not current_price:
        print("Error: no price data for %s" % symbol)
        return None

    stock_info = {
        "symbol": symbol,
        "price": current_price,
        "change": change,
        "change_pct": change_pct,
    }

    # Cache the result
    cache.set(cache_key, json.encode(stock_info), ttl_seconds = CACHE_TTL)

    return stock_info

def get_schema():
    """Define the configuration schema."""
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stocks",
                name = "Stock Symbols",
                desc = "Comma-separated stock symbols (e.g., AAPL,GOOGL,MSFT)",
                icon = "chartLine",
                default = DEFAULT_STOCKS,
            ),
            schema.Text(
                id = "api_key",
                name = "Finnhub API Key",
                desc = "Your Finnhub API key for real-time stock data",
                icon = "key",
                default = "",
            ),
        ],
    )
