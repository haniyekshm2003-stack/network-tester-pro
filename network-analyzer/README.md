# 🌐 Network Analyzer Pro

A comprehensive, professional, modular network analysis tool with a beautiful dark-themed dashboard.

## ✨ Features

### 🔍 Network Scanning
- **IP Detection**: Public & Local IP identification
- **ISP & Geolocation**: Automatic ISP and location detection
- **Latency Measurement**: Real-time ping with jitter analysis
- **Packet Loss Detection**: Monitor connection stability
- **Throughput Testing**: Download/Upload speed measurement
- **MTU Detection**: Optimal packet size detection
- **NAT Type Detection**: Identify NAT restrictions

### 🌐 DNS Benchmark
- Test 20+ DNS servers (Cloudflare, Google, Quad9, OpenDNS, AdGuard, etc.)
- Compare response times
- Get personalized DNS recommendations

### ☁️ CDN Testing
- Test 12+ CDN providers (Cloudflare, Fastly, Akamai, AWS, Google, Azure, etc.)
- Measure edge server latency
- Find optimal CDN for your location

### 📡 Protocol Benchmark
- HTTP/HTTPS performance
- TLS handshake timing
- HTTP/2 and HTTP/3 support detection
- TCP connection analysis

### 🔌 Port Scanner
- Safe, rate-limited port scanning
- Common service ports (HTTP, HTTPS, SSH, FTP, etc.)
- VPN-specific ports (OpenVPN, WireGuard, V2Ray, etc.)
- Detection of filtered/blocked ports

### 🌍 Global Ping Test
- Test 20+ global locations
- Find optimal server regions
- Visualize worldwide latency

### 🧠 Smart Recommendations
- Personalized optimization suggestions
- Best DNS, CDN, and location recommendations
- Connection architecture design

## 🚀 Quick Start

### Prerequisites
- Python 3.10+
- pip (Python package manager)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/network-analyzer.git
cd network-analyzer

# Install dependencies
pip install -r requirements.txt

# Run the server
python backend/main.py
```

### Access Dashboard
Open your browser and navigate to:
```
http://localhost:8080
```

## 📁 Project Structure

```
network-analyzer/
├── backend/
│   ├── main.py              # FastAPI main application
│   └── modules/
│       ├── __init__.py      # Module exports
│       ├── network_scanner.py   # Network analysis
│       ├── dns_analyzer.py      # DNS benchmarking
│       ├── cdn_tester.py        # CDN testing
│       ├── protocol_benchmark.py # Protocol testing
│       ├── port_scanner.py      # Port scanning
│       ├── global_ping.py       # Global latency testing
│       ├── recommendation_engine.py # Smart recommendations
│       └── service_architect.py # Architecture design
├── frontend/
│   ├── index.html           # Main dashboard
│   ├── css/
│   │   └── style.css        # Dark theme styling
│   └── js/
│       └── app.js           # Dashboard JavaScript
└── requirements.txt         # Python dependencies
```

## 🎨 Screenshots

### Dashboard
- Beautiful dark theme (GitHub-inspired)
- Real-time network score
- Interactive charts
- Sortable data tables

### Multi-Page Interface
- **Dashboard**: Overview of all metrics
- **Network Scan**: Detailed connection analysis
- **DNS Benchmark**: Compare DNS servers
- **CDN Test**: Test CDN providers
- **Global Ping**: Worldwide latency map
- **Protocol Benchmark**: Protocol performance
- **Port Scanner**: Port accessibility check
- **Recommendations**: AI-powered suggestions
- **Reports**: Export and save results

## 🔧 Configuration

### Custom DNS Servers
Edit `backend/modules/dns_analyzer.py` to add custom DNS servers.

### Custom CDN Providers
Edit `backend/modules/cdn_tester.py` to add custom CDN endpoints.

### Port List
Edit `backend/modules/port_scanner.py` to customize port scan targets.

## 📊 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/network/scan` | GET | Full network scan |
| `/api/network/ip` | GET | Public IP info |
| `/api/dns/test` | GET | DNS benchmark |
| `/api/cdn/test` | GET | CDN test |
| `/api/ping/test` | GET | Global ping test |
| `/api/protocol/test` | GET | Protocol benchmark |
| `/api/ports/scan` | GET | Port scan |
| `/api/recommendations` | POST | Get recommendations |

## 🔒 Security

- Rate-limited port scanning to prevent abuse
- No credentials stored
- All data processed locally
- No external data collection

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

MIT License - feel free to use this project for personal or commercial purposes.

## 🙏 Credits

- Chart.js for visualizations
- FastAPI for backend framework
- Cloudflare, Google, and other services for testing endpoints

---

Made with ❤️ for network optimization
