# Tidbyt Stock Ticker

A real-time stock ticker app for Tidbyt that displays current prices and percentage changes using Finnhub API.

## Features

- 📊 Real-time stock prices via Finnhub API
- 🎨 Color-coded changes (green = up, red = down)
- 📱 Scrolling display optimized for 64x32 LED matrix
- ⚡ 1-minute cache for performance
- 🔄 Automated updates during market hours (optional)
- 📝 **Multiple watchlists** with interactive management
- 🎯 **Quick switching** between different stock groups (tech, crypto, etc.)
- ⚡ **Batch operations** - add/remove multiple tickers in one session

## Quick Start

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd tidbyte
```

### 2. Set Up Configuration

**Environment variables:**
```bash
cp .env.example .env
```

Edit `.env` and fill in:
- `TIDBYT_DEVICE_ID` - Your Tidbyt device ID
- `TIDBYT_API_TOKEN` - Your Tidbyt API token
- `FINNHUB_API_KEY` - Your Finnhub API key ([Get one free](https://finnhub.io/))

**Watchlists:**
```bash
cp watchlists.example.json watchlists.json
```

Edit `watchlists.json` to customize your stock lists (or use the interactive manager below).

### 3. Test the App

```bash
./update_stocks.sh
```

Your Tidbyt should now display your stocks!

## Managing Watchlists

Use the interactive menu to manage your stock watchlists:

```bash
./manage_tickers.sh
```

**Features:**
- 📋 View all your watchlists
- 🔄 Switch between watchlists instantly
- ➕ Add multiple tickers in one session (loop until done)
- ➖ Remove multiple tickers in one session (loop until done)
- ✨ Create new watchlists (tech, crypto, personal, etc.)
- 🗑️ Delete watchlists
- 🚀 Update Tidbyt immediately with current watchlist

**Example workflow - Add multiple stocks:**
```bash
./manage_tickers.sh

# Select option 3: Add ticker to watchlist
# Choose "main" watchlist

Current tickers in main: SPY,AAPL,NVDA
Enter ticker: TSLA
✓ Added TSLA to main

Current tickers in main: SPY,AAPL,NVDA,TSLA
Enter ticker: META
✓ Added META to main

Current tickers in main: SPY,AAPL,NVDA,TSLA,META
Enter ticker: [Press Enter to finish]
Done adding tickers

# Select option 7: Update Tidbyt now
# Your display now shows all the new stocks!
```

**Example workflow - Switch watchlists:**
```bash
./manage_tickers.sh
# Select option 2: Switch active watchlist
# Choose "tech" watchlist
# Select option 7: Update Tidbyt now
# Your display now shows tech stocks!
```

## Manual Updates

To manually update with different stocks:

```bash
pixlet render stock_ticker.star \
    stocks="PLTR,NVDA,AAPL" \
    api_key="your-finnhub-key" \
    -o stock_ticker.webp

pixlet push \
    --api-token "your-tidbyt-token" \
    --installation-id stockticker \
    your-device-id \
    stock_ticker.webp
```

## Automated Updates

See [SETUP_AUTOMATION.md](SETUP_AUTOMATION.md) for instructions on setting up automatic updates during market hours using cron.

## Requirements

- [Pixlet](https://github.com/tidbyt/pixlet) CLI installed
- Tidbyt device
- Finnhub API key (free tier available)

## Configuration

### Environment Variables (`.env` file)

| Variable | Description | Example |
|----------|-------------|---------|
| `TIDBYT_DEVICE_ID` | Your Tidbyt device ID | `unequally-sought-completed-snipe-8e1` |
| `TIDBYT_API_TOKEN` | Your Tidbyt API token | `eyJhbG...` |
| `FINNHUB_API_KEY` | Your Finnhub API key | `d1uo0h9r01...` |
| `INSTALLATION_ID` | App installation ID | `stockticker` |

**Note:** `STOCK_SYMBOLS` is optional in `.env` - if `watchlists.json` exists, the app will use the active watchlist instead.

### Watchlists (`watchlists.json`)

The `watchlists.json` file stores all your watchlists:

```json
{
  "active": "main",
  "watchlists": {
    "main": ["SPY", "AAPL", "NVDA", "MSFT"],
    "tech": ["AAPL", "GOOGL", "MSFT", "NVDA", "TSLA"],
    "crypto": ["IBIT", "COIN", "MSTR"]
  }
}
```

- `active` - The currently active watchlist (what shows on your Tidbyt)
- `watchlists` - All your watchlist groups

**Tip:** Use `./manage_tickers.sh` to manage watchlists interactively instead of editing JSON manually!

## Files

- `stock_ticker.star` - Tidbyt app source code (Starlark)
- `update_stocks.sh` - Update script for automation
- `manage_tickers.sh` - Interactive watchlist manager
- `.env` - Your configuration (not committed to git)
- `.env.example` - Configuration template
- `watchlists.json` - Your personal watchlists (not committed to git)
- `watchlists.example.json` - Watchlist template
- `SETUP_AUTOMATION.md` - Automation setup guide

## Finnhub API Limits

Free tier: 60 API calls/minute

With 5 stocks updating every 5 minutes, you'll use ~1 call/minute, well within limits.

## Troubleshooting

**"ERROR: .env file not found!"**
- Copy `.env.example` to `.env` and fill in your values

**No data showing on Tidbyt:**
- Check that your device ID and API token are correct
- Verify your Finnhub API key is valid
- Check `stock_ticker.log` for errors

**Rate limit errors:**
- Reduce update frequency in cron job
- Use fewer stock symbols

## License

MIT
