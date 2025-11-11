#!/bin/bash

# Stock Ticker Auto-Update Script
# Updates Tidbyt with latest stock prices from Finnhub

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Path to pixlet (use full path for cron compatibility)
PIXLET="/opt/homebrew/bin/pixlet"

# Check if pixlet is installed
if [ ! -f "$PIXLET" ]; then
    # Try to find pixlet in PATH
    PIXLET=$(which pixlet 2>/dev/null)
    if [ -z "$PIXLET" ]; then
        echo "ERROR: pixlet not found!"
        echo "Please install pixlet: brew install tidbyt/tidbyt/pixlet"
        exit 1
    fi
fi

# Load environment variables from .env file
if [ -f .env ]; then
    source .env
else
    echo "ERROR: .env file not found!"
    echo "Please copy .env.example to .env and fill in your values."
    exit 1
fi

# Validate required environment variables
if [ -z "$TIDBYT_DEVICE_ID" ] || [ -z "$TIDBYT_API_TOKEN" ] || [ -z "$FINNHUB_API_KEY" ]; then
    echo "ERROR: Missing required environment variables in .env file"
    echo "Required: TIDBYT_DEVICE_ID, TIDBYT_API_TOKEN, FINNHUB_API_KEY"
    exit 1
fi

# Get stock symbols from watchlists.json if it exists, otherwise fall back to .env
WATCHLISTS_FILE="watchlists.json"
if [ -f "$WATCHLISTS_FILE" ]; then
    # Read active watchlist and its tickers from JSON
    ACTIVE_WATCHLIST=$(python3 -c "import json; data=json.load(open('$WATCHLISTS_FILE')); print(data.get('active', 'main'))")
    STOCK_SYMBOLS=$(python3 -c "import json; data=json.load(open('$WATCHLISTS_FILE')); print(','.join(data['watchlists'].get('$ACTIVE_WATCHLIST', [])))")

    if [ -z "$STOCK_SYMBOLS" ]; then
        echo "ERROR: No tickers found in active watchlist '$ACTIVE_WATCHLIST'"
        exit 1
    fi
else
    # Fall back to .env STOCK_SYMBOLS if watchlists.json doesn't exist
    if [ -z "$STOCK_SYMBOLS" ]; then
        echo "ERROR: No stock symbols configured"
        echo "Either create watchlists.json or set STOCK_SYMBOLS in .env"
        exit 1
    fi
    ACTIVE_WATCHLIST="default"
fi

# Set default installation ID if not provided
INSTALLATION_ID="${INSTALLATION_ID:-stockticker}"

# Set default scroll speed if not provided
SCROLL_SPEED="${SCROLL_SPEED:-normal}"

# Log file
LOG_FILE="$SCRIPT_DIR/stock_ticker.log"

# Timestamp for logging
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting stock ticker update" >> "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Watchlist: $ACTIVE_WATCHLIST" >> "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Stocks: $STOCK_SYMBOLS" >> "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Scroll Speed: $SCROLL_SPEED" >> "$LOG_FILE"

# Render the app with latest stock data
if $PIXLET render stock_ticker.star \
    stocks="$STOCK_SYMBOLS" \
    api_key="$FINNHUB_API_KEY" \
    scroll_speed="$SCROLL_SPEED" \
    -o stock_ticker.webp >> "$LOG_FILE" 2>&1; then

    echo "$(date '+%Y-%m-%d %H:%M:%S') - Render successful" >> "$LOG_FILE"

    # Push to Tidbyt device
    if $PIXLET push \
        --api-token "$TIDBYT_API_TOKEN" \
        --installation-id "$INSTALLATION_ID" \
        "$TIDBYT_DEVICE_ID" \
        stock_ticker.webp >> "$LOG_FILE" 2>&1; then

        echo "$(date '+%Y-%m-%d %H:%M:%S') - Push successful" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Push failed" >> "$LOG_FILE"
        exit 1
    fi
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Render failed" >> "$LOG_FILE"
    exit 1
fi
