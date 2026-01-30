#!/usr/bin/env python3
"""
🔌 Port Scanner Module
======================
Safe port scanning with rate limiting.
"""

import asyncio
import time
from typing import Dict, List, Any
import logging

logger = logging.getLogger(__name__)

# =============================================================================
# 📊 PORT DATABASE
# =============================================================================

COMMON_PORTS = {
    20: {"name": "FTP Data", "service": "ftp-data", "category": "file"},
    21: {"name": "FTP Control", "service": "ftp", "category": "file"},
    22: {"name": "SSH", "service": "ssh", "category": "remote"},
    23: {"name": "Telnet", "service": "telnet", "category": "remote"},
    25: {"name": "SMTP", "service": "smtp", "category": "mail"},
    53: {"name": "DNS", "service": "dns", "category": "network"},
    80: {"name": "HTTP", "service": "http", "category": "web"},
    110: {"name": "POP3", "service": "pop3", "category": "mail"},
    143: {"name": "IMAP", "service": "imap", "category": "mail"},
    443: {"name": "HTTPS", "service": "https", "category": "web"},
    465: {"name": "SMTPS", "service": "smtps", "category": "mail"},
    587: {"name": "SMTP Submission", "service": "submission", "category": "mail"},
    993: {"name": "IMAPS", "service": "imaps", "category": "mail"},
    995: {"name": "POP3S", "service": "pop3s", "category": "mail"},
    1080: {"name": "SOCKS Proxy", "service": "socks", "category": "proxy"},
    1194: {"name": "OpenVPN", "service": "openvpn", "category": "vpn"},
    1433: {"name": "MSSQL", "service": "mssql", "category": "database"},
    1521: {"name": "Oracle DB", "service": "oracle", "category": "database"},
    3306: {"name": "MySQL", "service": "mysql", "category": "database"},
    3389: {"name": "RDP", "service": "rdp", "category": "remote"},
    5432: {"name": "PostgreSQL", "service": "postgresql", "category": "database"},
    5900: {"name": "VNC", "service": "vnc", "category": "remote"},
    6379: {"name": "Redis", "service": "redis", "category": "database"},
    8080: {"name": "HTTP Proxy", "service": "http-proxy", "category": "proxy"},
    8443: {"name": "HTTPS Alt", "service": "https-alt", "category": "web"},
    8888: {"name": "HTTP Alt", "service": "http-alt", "category": "web"},
    27017: {"name": "MongoDB", "service": "mongodb", "category": "database"},
}

# VPN and Proxy specific ports
VPN_PORTS = {
    443: {"name": "HTTPS/TLS", "protocols": ["VLESS", "Trojan", "VMess", "SS"]},
    80: {"name": "HTTP", "protocols": ["VMess", "HTTP Proxy"]},
    8080: {"name": "HTTP Proxy", "protocols": ["HTTP Proxy", "VMess"]},
    8443: {"name": "HTTPS Alt", "protocols": ["VLESS", "Trojan"]},
    2053: {"name": "Cloudflare", "protocols": ["VLESS", "Trojan"]},
    2083: {"name": "Cloudflare TLS", "protocols": ["VLESS", "Trojan"]},
    2087: {"name": "Cloudflare TLS", "protocols": ["VLESS", "Trojan"]},
    2096: {"name": "Cloudflare TLS", "protocols": ["VLESS", "Trojan"]},
    1194: {"name": "OpenVPN", "protocols": ["OpenVPN"]},
    51820: {"name": "WireGuard", "protocols": ["WireGuard"]},
    500: {"name": "IKEv2/IPsec", "protocols": ["IKEv2"]},
    4500: {"name": "IPsec NAT-T", "protocols": ["IKEv2", "L2TP"]},
    1701: {"name": "L2TP", "protocols": ["L2TP"]},
    1723: {"name": "PPTP", "protocols": ["PPTP"]},
}

# =============================================================================
# 🔧 PORT SCANNER CLASS
# =============================================================================


class PortScanner:
    """Safe port scanner with rate limiting"""

    def __init__(self):
        self.timeout = 3.0
        self.rate_limit = 0.05  # seconds between scans
        self.max_concurrent = 20

    # =========================================================================
    # 🔍 PORT SCAN
    # =========================================================================

    async def scan_port(
        self, host: str, port: int, timeout: float = None
    ) -> Dict[str, Any]:
        """Scan a single port"""
        timeout = timeout or self.timeout

        try:
            start = time.perf_counter()

            # Attempt TCP connection
            reader, writer = await asyncio.wait_for(
                asyncio.open_connection(host, port), timeout=timeout
            )

            end = time.perf_counter()
            latency = (end - start) * 1000

            writer.close()
            await writer.wait_closed()

            port_info = COMMON_PORTS.get(port, {})

            return {
                "port": port,
                "status": "open",
                "latency_ms": round(latency, 2),
                "name": port_info.get("name", "Unknown"),
                "service": port_info.get("service", "unknown"),
                "category": port_info.get("category", "other"),
            }

        except asyncio.TimeoutError:
            return {
                "port": port,
                "status": "filtered",
                "latency_ms": timeout * 1000,
                "name": COMMON_PORTS.get(port, {}).get("name", "Unknown"),
                "service": COMMON_PORTS.get(port, {}).get("service", "unknown"),
                "category": COMMON_PORTS.get(port, {}).get("category", "other"),
            }
        except ConnectionRefusedError:
            return {
                "port": port,
                "status": "closed",
                "latency_ms": 0,
                "name": COMMON_PORTS.get(port, {}).get("name", "Unknown"),
                "service": COMMON_PORTS.get(port, {}).get("service", "unknown"),
                "category": COMMON_PORTS.get(port, {}).get("category", "other"),
            }
        except Exception as e:
            return {
                "port": port,
                "status": "error",
                "latency_ms": 0,
                "error": str(e),
                "name": COMMON_PORTS.get(port, {}).get("name", "Unknown"),
                "service": COMMON_PORTS.get(port, {}).get("service", "unknown"),
                "category": COMMON_PORTS.get(port, {}).get("category", "other"),
            }

    async def scan(
        self, ports: List[int], timeout: float = None, host: str = "8.8.8.8"
    ) -> Dict[str, Any]:
        """Scan multiple ports with rate limiting"""
        results = {
            "host": host,
            "ports": [],
            "open": [],
            "closed": [],
            "filtered": [],
            "summary": {},
        }

        semaphore = asyncio.Semaphore(self.max_concurrent)

        async def scan_with_limit(port: int):
            async with semaphore:
                result = await self.scan_port(host, port, timeout)
                await asyncio.sleep(self.rate_limit)
                return result

        # Scan all ports concurrently
        tasks = [scan_with_limit(port) for port in ports]
        port_results = await asyncio.gather(*tasks)

        for result in port_results:
            results["ports"].append(result)

            if result["status"] == "open":
                results["open"].append(result["port"])
            elif result["status"] == "closed":
                results["closed"].append(result["port"])
            elif result["status"] == "filtered":
                results["filtered"].append(result["port"])

        # Summary
        results["summary"] = {
            "total_scanned": len(ports),
            "open_count": len(results["open"]),
            "closed_count": len(results["closed"]),
            "filtered_count": len(results["filtered"]),
            "open_ports": results["open"],
        }

        return results

    async def scan_common_ports(self, host: str = "8.8.8.8") -> Dict[str, Any]:
        """Scan common ports"""
        ports = list(COMMON_PORTS.keys())
        return await self.scan(ports, host=host)

    async def scan_vpn_ports(self, host: str = "8.8.8.8") -> Dict[str, Any]:
        """Scan VPN-related ports"""
        ports = list(VPN_PORTS.keys())
        results = await self.scan(ports, host=host)

        # Add VPN-specific info
        for port_result in results["ports"]:
            port = port_result["port"]
            if port in VPN_PORTS:
                port_result["vpn_info"] = VPN_PORTS[port]

        return results

    # =========================================================================
    # 📊 PORT RECOMMENDATIONS
    # =========================================================================

    def get_port_recommendations(self, scan_results: Dict[str, Any]) -> Dict[str, Any]:
        """Generate port recommendations based on scan"""
        open_ports = scan_results.get("open", [])

        recommendations = {
            "web_ports": [],
            "vpn_ports": [],
            "proxy_ports": [],
            "best_for_tunnel": None,
            "notes": [],
        }

        # Categorize open ports
        for port in open_ports:
            if port in [80, 443, 8080, 8443]:
                recommendations["web_ports"].append(port)
            if port in VPN_PORTS:
                recommendations["vpn_ports"].append({"port": port, **VPN_PORTS[port]})
            if port in [1080, 8080, 3128]:
                recommendations["proxy_ports"].append(port)

        # Best port for tunneling
        preferred_order = [443, 8443, 2053, 2083, 80, 8080]
        for port in preferred_order:
            if port in open_ports:
                recommendations["best_for_tunnel"] = {
                    "port": port,
                    "reason": "Common and less likely to be blocked",
                }
                break

        # Generate notes
        if 443 in open_ports:
            recommendations["notes"].append(
                "Port 443 (HTTPS) is open - best for TLS-based tunnels"
            )
        if 80 in open_ports and 443 not in open_ports:
            recommendations["notes"].append(
                "Only HTTP (80) is open - consider using WebSocket"
            )
        if not recommendations["web_ports"]:
            recommendations["notes"].append(
                "No common web ports open - network may be restricted"
            )

        return recommendations
