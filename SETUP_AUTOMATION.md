# Stock Ticker Automation Setup

This guide will help you set up automatic updates for your Tidbyt stock ticker during market hours (8:30 AM - 3:00 PM CT, Monday-Friday).

## Prerequisites

1. **Pixlet installed** on your always-on Mac:
   ```bash
   brew install tidbyt/tidbyt/pixlet
   ```

2. **Git repository cloned** on your always-on Mac

## Setup Instructions

### 1. Clone the Repository

On your always-on Mac:

```bash
cd ~/Projects  # or wherever you want to store it
git clone <your-repo-url> tidbyte
cd tidbyte
```

### 2. Configure Your Environment

Copy the example configuration file:

```bash
cp .env.example .env
```

Edit the `.env` file with your actual values:

```bash
nano .env  # or use your preferred editor
```

Fill in all required values:
- `TIDBYT_DEVICE_ID` - Your Tidbyt device ID
- `TIDBYT_API_TOKEN` - Your Tidbyt API token
- `FINNHUB_API_KEY` - Your Finnhub API key
- `STOCK_SYMBOLS` - The stocks you want to track (comma-separated, no spaces)

**Important:** The `.env` file is gitignored and will NOT be committed to your repository. This keeps your secrets safe!

### 3. Test the Script

Make sure the script is executable:

```bash
chmod +x update_stocks.sh
```

Test it manually:

```bash
./update_stocks.sh
```

Check your Tidbyt to verify the update worked, then review the log:

```bash
tail stock_ticker.log
```

### 4. Set Up Cron Job

Open the crontab editor:

```bash
crontab -e
```

**Important:** Update the path below to match where you cloned the repository!

Add these lines to run every 5 minutes during market hours (8:30 AM - 3:00 PM CT, Mon-Fri):

```cron
# Update Tidbyt stock ticker every 5 minutes during market hours (CT)
# Runs 8:30-8:55 AM
30-59/5 8 * * 1-5 /Users/YOURUSERNAME/Projects/tidbyte/update_stocks.sh

# Runs 9:00 AM - 2:55 PM
*/5 9-14 * * 1-5 /Users/YOURUSERNAME/Projects/tidbyte/update_stocks.sh

# Runs at 3:00 PM
0 15 * * 1-5 /Users/YOURUSERNAME/Projects/tidbyte/update_stocks.sh
```

**Remember:** Replace `/Users/YOURUSERNAME/Projects/tidbyte` with your actual path!

Save and exit (`:wq` if using vim).

### 5. Verify Cron Setup

Check that the cron jobs were added:

```bash
crontab -l
```

### 6. Monitor the Logs

Watch updates in real-time:

```bash
tail -f ~/Projects/tidbyte/stock_ticker.log
```

Or check recent activity:

```bash
tail -20 ~/Projects/tidbyte/stock_ticker.log
```

## Customization

### Change Stock Symbols

Edit your `.env` file:

```bash
STOCK_SYMBOLS=AAPL,GOOGL,MSFT,TSLA,NVDA
```

### Change Update Frequency

**Every 2 minutes:**
```cron
30-59/2 8 * * 1-5 /path/to/update_stocks.sh
*/2 9-14 * * 1-5 /path/to/update_stocks.sh
0 15 * * 1-5 /path/to/update_stocks.sh
```

**Every 10 minutes:**
```cron
30-59/10 8 * * 1-5 /path/to/update_stocks.sh
*/10 9-14 * * 1-5 /path/to/update_stocks.sh
0 15 * * 1-5 /path/to/update_stocks.sh
```

### Change Market Hours

Edit the hour ranges in the crontab:
- `8` = 8:00 AM CT
- `9-14` = 9:00 AM - 2:59 PM CT
- `15` = 3:00 PM CT

For different time zones, adjust accordingly.

## Troubleshooting

### ".env file not found" Error

Make sure you copied `.env.example` to `.env`:
```bash
cp .env.example .env
```

Then edit it with your actual values.

### Updates Not Running

**1. Check cron permissions:**
   - System Preferences → Security & Privacy → Privacy → Full Disk Access
   - Add Terminal or `/usr/sbin/cron` to the list

**2. Ensure pixlet is accessible to cron:**

Find pixlet location:
```bash
which pixlet
```

If it's in a non-standard location (like `/opt/homebrew/bin/pixlet`), you may need to update the script or add it to cron's PATH:

```cron
PATH=/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin
30-59/5 8 * * 1-5 /path/to/update_stocks.sh
...
```

**3. Check the log for errors:**
```bash
cat stock_ticker.log
```

**4. Test the script manually:**
```bash
./update_stocks.sh
echo $?  # Should output 0 if successful
```

### Rate Limiting

Finnhub free tier: 60 API calls/minute

- 5 stocks × 1 API call each = 5 calls per update
- Updating every 5 minutes = ~1 call/minute average
- Well within limits!

If you hit rate limits:
- Reduce number of stocks
- Increase time between updates
- Upgrade to Finnhub paid tier

### Wrong Prices or Stale Data

- Finnhub updates in near real-time during market hours
- After-hours prices may not update as frequently
- Cache is set to 60 seconds - prices refresh on each render

## Stopping Automation

To temporarily disable:

```bash
crontab -e
```

Comment out the lines by adding `#`:

```cron
# 30-59/5 8 * * 1-5 /path/to/update_stocks.sh
# */5 9-14 * * 1-5 /path/to/update_stocks.sh
# 0 15 * * 1-5 /path/to/update_stocks.sh
```

To completely remove:

```bash
crontab -r  # Removes ALL cron jobs for your user!
```

## Multi-Mac Setup

Since secrets are in `.env` (not committed to git):

1. Clone the repo on each Mac
2. Create a separate `.env` file on each Mac with the same values
3. The repository stays clean and shareable!

## Security Notes

- ✅ `.env` is gitignored - your secrets are safe
- ✅ Never commit `.env` to git
- ✅ Share `.env.example` (without real values) in git
- ✅ Each Mac gets its own `.env` file locally
