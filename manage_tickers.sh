#!/bin/bash

# Tidbyt Stock Ticker Watchlist Manager
# Interactive menu to manage multiple watchlists

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

WATCHLISTS_FILE="watchlists.json"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if watchlists.json exists
if [ ! -f "$WATCHLISTS_FILE" ]; then
    echo -e "${RED}ERROR: $WATCHLISTS_FILE not found!${NC}"
    echo "Creating from template..."
    if [ -f "watchlists.example.json" ]; then
        cp watchlists.example.json "$WATCHLISTS_FILE"
        echo -e "${GREEN}Created $WATCHLISTS_FILE${NC}"
    else
        echo -e "${RED}Template not found. Please create $WATCHLISTS_FILE manually.${NC}"
        exit 1
    fi
fi

# Function to read JSON value
get_json_value() {
    local key=$1
    python3 -c "import json; data=json.load(open('$WATCHLISTS_FILE')); print(data.get('$key', ''))"
}

# Function to get active watchlist name
get_active_watchlist() {
    python3 -c "import json; data=json.load(open('$WATCHLISTS_FILE')); print(data.get('active', 'main'))"
}

# Function to get tickers from a watchlist
get_watchlist_tickers() {
    local name=$1
    python3 -c "import json; data=json.load(open('$WATCHLISTS_FILE')); print(','.join(data['watchlists'].get('$name', [])))"
}

# Function to list all watchlists
list_watchlists() {
    python3 -c "import json; data=json.load(open('$WATCHLISTS_FILE')); print('\n'.join(data['watchlists'].keys()))"
}

# Function to count tickers in a watchlist
count_tickers() {
    local name=$1
    python3 -c "import json; data=json.load(open('$WATCHLISTS_FILE')); print(len(data['watchlists'].get('$name', [])))"
}

# Function to set active watchlist
set_active_watchlist() {
    local name=$1
    python3 << EOF
import json
with open('$WATCHLISTS_FILE', 'r') as f:
    data = json.load(f)
data['active'] = '$name'
with open('$WATCHLISTS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
EOF
    echo -e "${GREEN}Active watchlist set to: $name${NC}"
}

# Function to add ticker to watchlist
add_ticker() {
    local watchlist=$1
    local ticker=$2
    python3 << EOF
import json
with open('$WATCHLISTS_FILE', 'r') as f:
    data = json.load(f)
if '$watchlist' not in data['watchlists']:
    data['watchlists']['$watchlist'] = []
if '$ticker' not in data['watchlists']['$watchlist']:
    data['watchlists']['$watchlist'].append('$ticker')
    print('added')
else:
    print('exists')
with open('$WATCHLISTS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
EOF
}

# Function to remove ticker from watchlist
remove_ticker() {
    local watchlist=$1
    local ticker=$2
    python3 << EOF
import json
with open('$WATCHLISTS_FILE', 'r') as f:
    data = json.load(f)
if '$watchlist' in data['watchlists'] and '$ticker' in data['watchlists']['$watchlist']:
    data['watchlists']['$watchlist'].remove('$ticker')
    print('removed')
else:
    print('notfound')
with open('$WATCHLISTS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
EOF
}

# Function to create new watchlist
create_watchlist() {
    local name=$1
    python3 << EOF
import json
with open('$WATCHLISTS_FILE', 'r') as f:
    data = json.load(f)
if '$name' in data['watchlists']:
    print('exists')
else:
    data['watchlists']['$name'] = []
    print('created')
with open('$WATCHLISTS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
EOF
}

# Function to delete watchlist
delete_watchlist() {
    local name=$1
    python3 << EOF
import json
with open('$WATCHLISTS_FILE', 'r') as f:
    data = json.load(f)
if '$name' in data['watchlists']:
    del data['watchlists']['$name']
    if data.get('active') == '$name':
        # Set first available watchlist as active
        data['active'] = list(data['watchlists'].keys())[0] if data['watchlists'] else 'main'
    print('deleted')
else:
    print('notfound')
with open('$WATCHLISTS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
EOF
}

# Function to display header
show_header() {
    clear
    echo -e "${CYAN}=================================${NC}"
    echo -e "${CYAN}  TIDBYT STOCK TICKER MANAGER${NC}"
    echo -e "${CYAN}=================================${NC}"
    echo ""

    local active=$(get_active_watchlist)
    local count=$(count_tickers "$active")
    local tickers=$(get_watchlist_tickers "$active")

    echo -e "${GREEN}Active Watchlist:${NC} $active (${count} stocks)"
    echo -e "${YELLOW}Tickers:${NC} $tickers"
    echo ""
}

# Function to view all watchlists
view_all_watchlists() {
    show_header
    echo -e "${BLUE}=== ALL WATCHLISTS ===${NC}"
    echo ""

    local active=$(get_active_watchlist)

    while IFS= read -r watchlist; do
        local count=$(count_tickers "$watchlist")
        local tickers=$(get_watchlist_tickers "$watchlist")

        if [ "$watchlist" = "$active" ]; then
            echo -e "${GREEN}★ $watchlist${NC} ($count stocks)"
        else
            echo -e "  $watchlist ($count stocks)"
        fi
        echo -e "  ${YELLOW}→${NC} $tickers"
        echo ""
    done < <(list_watchlists)

    echo ""
    read -p "Press Enter to continue..."
}

# Function to switch active watchlist
switch_watchlist() {
    show_header
    echo -e "${BLUE}=== SWITCH ACTIVE WATCHLIST ===${NC}"
    echo ""

    local i=1
    declare -A watchlist_map

    while IFS= read -r watchlist; do
        echo "$i. $watchlist ($(count_tickers "$watchlist") stocks)"
        watchlist_map[$i]=$watchlist
        ((i++))
    done < <(list_watchlists)

    echo ""
    read -p "Select watchlist number (or 0 to cancel): " choice

    if [ "$choice" -eq 0 ] 2>/dev/null; then
        return
    fi

    if [ -n "${watchlist_map[$choice]}" ]; then
        set_active_watchlist "${watchlist_map[$choice]}"
        read -p "Press Enter to continue..."
    else
        echo -e "${RED}Invalid selection${NC}"
        read -p "Press Enter to continue..."
    fi
}

# Function to add ticker to watchlist
add_ticker_menu() {
    show_header
    echo -e "${BLUE}=== ADD TICKER TO WATCHLIST ===${NC}"
    echo ""

    local i=1
    declare -A watchlist_map

    while IFS= read -r watchlist; do
        echo "$i. $watchlist"
        watchlist_map[$i]=$watchlist
        ((i++))
    done < <(list_watchlists)

    echo ""
    read -p "Select watchlist number (or 0 to cancel): " choice

    if [ "$choice" -eq 0 ] 2>/dev/null; then
        return
    fi

    if [ -n "${watchlist_map[$choice]}" ]; then
        local selected="${watchlist_map[$choice]}"
        read -p "Enter ticker symbol (e.g., AAPL): " ticker
        ticker=$(echo "$ticker" | tr '[:lower:]' '[:upper:]')

        if [ -z "$ticker" ]; then
            echo -e "${RED}No ticker entered${NC}"
            read -p "Press Enter to continue..."
            return
        fi

        local result=$(add_ticker "$selected" "$ticker")
        if [ "$result" = "added" ]; then
            echo -e "${GREEN}Added $ticker to $selected${NC}"
        else
            echo -e "${YELLOW}$ticker already exists in $selected${NC}"
        fi
        read -p "Press Enter to continue..."
    else
        echo -e "${RED}Invalid selection${NC}"
        read -p "Press Enter to continue..."
    fi
}

# Function to remove ticker from watchlist
remove_ticker_menu() {
    show_header
    echo -e "${BLUE}=== REMOVE TICKER FROM WATCHLIST ===${NC}"
    echo ""

    local i=1
    declare -A watchlist_map

    while IFS= read -r watchlist; do
        echo "$i. $watchlist ($(get_watchlist_tickers "$watchlist"))"
        watchlist_map[$i]=$watchlist
        ((i++))
    done < <(list_watchlists)

    echo ""
    read -p "Select watchlist number (or 0 to cancel): " choice

    if [ "$choice" -eq 0 ] 2>/dev/null; then
        return
    fi

    if [ -n "${watchlist_map[$choice]}" ]; then
        local selected="${watchlist_map[$choice]}"
        read -p "Enter ticker symbol to remove: " ticker
        ticker=$(echo "$ticker" | tr '[:lower:]' '[:upper:]')

        if [ -z "$ticker" ]; then
            echo -e "${RED}No ticker entered${NC}"
            read -p "Press Enter to continue..."
            return
        fi

        local result=$(remove_ticker "$selected" "$ticker")
        if [ "$result" = "removed" ]; then
            echo -e "${GREEN}Removed $ticker from $selected${NC}"
        else
            echo -e "${RED}$ticker not found in $selected${NC}"
        fi
        read -p "Press Enter to continue..."
    else
        echo -e "${RED}Invalid selection${NC}"
        read -p "Press Enter to continue..."
    fi
}

# Function to create new watchlist
create_watchlist_menu() {
    show_header
    echo -e "${BLUE}=== CREATE NEW WATCHLIST ===${NC}"
    echo ""

    read -p "Enter new watchlist name: " name

    if [ -z "$name" ]; then
        echo -e "${RED}No name entered${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    local result=$(create_watchlist "$name")
    if [ "$result" = "created" ]; then
        echo -e "${GREEN}Created watchlist: $name${NC}"
    else
        echo -e "${RED}Watchlist $name already exists${NC}"
    fi
    read -p "Press Enter to continue..."
}

# Function to delete watchlist
delete_watchlist_menu() {
    show_header
    echo -e "${BLUE}=== DELETE WATCHLIST ===${NC}"
    echo ""

    local i=1
    declare -A watchlist_map

    while IFS= read -r watchlist; do
        echo "$i. $watchlist"
        watchlist_map[$i]=$watchlist
        ((i++))
    done < <(list_watchlists)

    echo ""
    read -p "Select watchlist to delete (or 0 to cancel): " choice

    if [ "$choice" -eq 0 ] 2>/dev/null; then
        return
    fi

    if [ -n "${watchlist_map[$choice]}" ]; then
        local selected="${watchlist_map[$choice]}"
        read -p "Are you sure you want to delete '$selected'? (y/N): " confirm

        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            local result=$(delete_watchlist "$selected")
            if [ "$result" = "deleted" ]; then
                echo -e "${GREEN}Deleted watchlist: $selected${NC}"
            else
                echo -e "${RED}Error deleting $selected${NC}"
            fi
        fi
        read -p "Press Enter to continue..."
    else
        echo -e "${RED}Invalid selection${NC}"
        read -p "Press Enter to continue..."
    fi
}

# Function to update Tidbyt now
update_tidbyt_now() {
    show_header
    echo -e "${BLUE}=== UPDATE TIDBYT NOW ===${NC}"
    echo ""

    local active=$(get_active_watchlist)
    local tickers=$(get_watchlist_tickers "$active")

    echo -e "Updating with watchlist: ${GREEN}$active${NC}"
    echo -e "Tickers: ${YELLOW}$tickers${NC}"
    echo ""

    if [ -f "./update_stocks.sh" ]; then
        ./update_stocks.sh
        echo ""
        echo -e "${GREEN}Update complete!${NC}"
    else
        echo -e "${RED}ERROR: update_stocks.sh not found${NC}"
    fi

    echo ""
    read -p "Press Enter to continue..."
}

# Main menu loop
main_menu() {
    while true; do
        show_header
        echo -e "${BLUE}=== MAIN MENU ===${NC}"
        echo ""
        echo "1. View all watchlists"
        echo "2. Switch active watchlist"
        echo "3. Add ticker to watchlist"
        echo "4. Remove ticker from watchlist"
        echo "5. Create new watchlist"
        echo "6. Delete watchlist"
        echo "7. Update Tidbyt now"
        echo "8. Exit"
        echo ""
        read -p "Select option: " choice

        case $choice in
            1) view_all_watchlists ;;
            2) switch_watchlist ;;
            3) add_ticker_menu ;;
            4) remove_ticker_menu ;;
            5) create_watchlist_menu ;;
            6) delete_watchlist_menu ;;
            7) update_tidbyt_now ;;
            8) echo "Goodbye!"; exit 0 ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# Start the menu
main_menu
