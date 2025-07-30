# Domain Latency Tester

This repository contains a simple shell script to test the latency of a predefined list of domains. It helps you quickly find the top 5 domains with the lowest latency from your VPS.

## Usage

To run the script directly on your VPS, use the following command:

```bash
bash <(curl -sL https://raw.githubusercontent.com/ccxkai233/Domain_Selector/main/domain_check.sh)
```

The script will:
- Ping a list of high-reputation domains (Apple, Microsoft, AWS, etc.).
- Calculate the average latency for each domain.
- Display a sorted list of the top 5 domains with the lowest latency.

## Contributing

Feel free to add more high-quality domains to the list in `domain_check.sh` by submitting a pull request.