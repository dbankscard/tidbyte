#!/bin/bash

# Stock Ticker Auto-Update Script
# Updates Tidbyt with latest stock prices from Finnhub

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Load environment variables from .env file
if [ -f .env ]; then
    source .env
else
    echo "ERROR: .env file not found!"
    echo "Please copy .env.example to .env and fill in your values."
    exit 1
fi

# Validate required environment variables
if [ -z "$TIDBYT_DEVICE_ID" ] || [ -z "$TIDBYT_API_TOKEN" ] || [ -z "$FINNHUB_API_KEY" ] || [ -z "$STOCK_SYMBOLS" ]; then
    echo "ERROR: Missing required environment variables in .env file"
    echo "Required: TIDBYT_DEVICE_ID, TIDBYT_API_TOKEN, FINNHUB_API_KEY, STOCK_SYMBOLS"
    exit 1
fi

# Set default installation ID if not provided
INSTALLATION_ID="${INSTALLATION_ID:-stockticker}"

# Log file
LOG_FILE="$SCRIPT_DIR/stock_ticker.log"

# Timestamp for logging
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting stock ticker update" >> "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Stocks: $STOCK_SYMBOLS" >> "$LOG_FILE"

# Render the app with latest stock data
if pixlet render stock_ticker.star \
    stocks="$STOCK_SYMBOLS" \
    api_key="$FINNHUB_API_KEY" \
    -o stock_ticker.webp >> "$LOG_FILE" 2>&1; then

    echo "$(date '+%Y-%m-%d %H:%M:%S') - Render successful" >> "$LOG_FILE"

    # Push to Tidbyt device
    if pixlet push \
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
