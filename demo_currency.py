CURRENCY_NAMES = {
    "EUR": "Euro",
    "USD": "US Dollar",
    "GBP": "British Pound",
    "JPY": "Japanese Yen",
    "CHF": "Swiss Franc",
    "AUD": "Australian Dollar",
    "CAD": "Canadian Dollar",
    "NZD": "New Zealand Dollar",
}

def format_pair(symbol: str) -> str:
    base = symbol[:3].upper()
    quote = symbol[3:].upper()
    base_name = CURRENCY_NAMES.get(base, base)
    quote_name = CURRENCY_NAMES.get(quote, quote)
    return f"{base}/{quote} — {base_name} / {quote_name}"

# Demo
pairs = ["EURUSD", "GBPUSD", "USDJPY", "EURGBP"]
for pair in pairs:
    print(format_pair(pair))
