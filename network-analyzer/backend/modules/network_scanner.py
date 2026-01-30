#!/usr/bin/env python3
"""
🔍 Network Scanner Module
=========================
Comprehensive network scanning and analysis engine.
"""

import asyncio
import socket
import struct
import time
import platform
import subprocess
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
import aiohttp
import logging

logger = logging.getLogger(__name__)

# =============================================================================
# 📊 DATA CLASSES
# =============================================================================


@dataclass
class NetworkInfo:
    """Network information data class"""

    hostname: str
    local_ip: str
    public_ip: str
    gateway: str
    dns_servers: List[str]
    mac_address: str
    interface: str
    isp: str
    country: str
    city: str
    asn: str
    org: str


@dataclass
class ConnectionQuality:
    """Connection quality metrics"""

    latency_ms: float
    jitter_ms: float
    packet_loss: float
    download_mbps: float
    upload_mbps: float
    mtu: int
    nat_type: str
    stability_score: int


# =============================================================================
# 🔧 NETWORK SCANNER CLASS
# =============================================================================


class NetworkScanner:
    """Advanced network scanner and analyzer"""

    # IP detection services
    IP_SERVICES = [
        "https://api.ipify.org?format=json",
        "https://ipinfo.io/json",
        "https://api.ip.sb/geoip",
        "https://ifconfig.me/all.json",
    ]

    # Test endpoints for latency
    LATENCY_ENDPOINTS = [
        "1.1.1.1",  # Cloudflare
        "8.8.8.8",  # Google
        "208.67.222.222",  # OpenDNS
        "9.9.9.9",  # Quad9
    ]

    def __init__(self):
        self.timeout = 10
        self.session = None

    async def get_session(self) -> aiohttp.ClientSession:
        """Get or create aiohttp session"""
        if self.session is None or self.session.closed:
            self.session = aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=self.timeout)
            )
        return self.session

    async def close(self):
        """Close session"""
        if self.session and not self.session.closed:
            await self.session.close()

    # =========================================================================
    # 🌐 PUBLIC IP DETECTION
    # =========================================================================

    async def get_public_ip_info(self) -> Dict[str, Any]:
        """Get public IP and geolocation info"""
        session = await self.get_session()

        for service_url in self.IP_SERVICES:
            try:
                async with session.get(service_url) as response:
                    if response.status == 200:
                        data = await response.json()

                        # Normalize response
                        return {
                            "public_ip": data.get("ip", data.get("query", "")),
                            "country": data.get(
                                "country", data.get("country_name", "")
                            ),
                            "country_code": data.get(
                                "country_code", data.get("countryCode", "")
                            ),
                            "city": data.get("city", ""),
                            "region": data.get("region", data.get("regionName", "")),
                            "isp": data.get("isp", data.get("org", "")),
                            "asn": data.get("asn", data.get("as", "")),
                            "org": data.get("org", data.get("organization", "")),
                            "timezone": data.get("timezone", ""),
                            "latitude": data.get("lat", data.get("latitude", 0)),
                            "longitude": data.get("lon", data.get("longitude", 0)),
                        }
            except Exception as e:
                logger.warning(f"IP service {service_url} failed: {e}")
                continue

        return {"public_ip": "Unknown", "error": "All IP services failed"}

    # =========================================================================
    # 🏠 LOCAL NETWORK INFO
    # =========================================================================

    def get_local_ip(self) -> str:
        """Get local IP address"""
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return "127.0.0.1"

    def get_hostname(self) -> str:
        """Get hostname"""
        return socket.gethostname()

    def get_gateway(self) -> str:
        """Get default gateway"""
        try:
            if platform.system() == "Windows":
                result = subprocess.run(["ipconfig"], capture_output=True, text=True)
                for line in result.stdout.split("\n"):
                    if "Default Gateway" in line:
                        parts = line.split(":")
                        if len(parts) > 1:
                            gw = parts[1].strip()
                            if gw:
                                return gw
            else:
                result = subprocess.run(
                    ["ip", "route", "show", "default"], capture_output=True, text=True
                )
                parts = result.stdout.split()
                if "via" in parts:
                    idx = parts.index("via")
                    return parts[idx + 1]
        except:
            pass
        return "Unknown"

    def get_dns_servers(self) -> List[str]:
        """Get configured DNS servers"""
        dns_servers = []
        try:
            if platform.system() == "Windows":
                result = subprocess.run(
                    ["ipconfig", "/all"], capture_output=True, text=True
                )
                for line in result.stdout.split("\n"):
                    if "DNS Servers" in line:
                        parts = line.split(":")
                        if len(parts) > 1:
                            dns_servers.append(parts[1].strip())
            else:
                with open("/etc/resolv.conf", "r") as f:
                    for line in f:
                        if line.startswith("nameserver"):
                            dns_servers.append(line.split()[1])
        except:
            pass
        return dns_servers or ["Unknown"]

    # =========================================================================
    # ⚡ LATENCY & JITTER MEASUREMENT
    # =========================================================================

    async def measure_latency(self, host: str, count: int = 10) -> Dict[str, float]:
        """Measure latency to a host"""
        latencies = []

        for _ in range(count):
            try:
                start = time.perf_counter()

                # TCP connection test
                reader, writer = await asyncio.wait_for(
                    asyncio.open_connection(host, 80), timeout=5
                )

                end = time.perf_counter()
                latency = (end - start) * 1000  # ms
                latencies.append(latency)

                writer.close()
                await writer.wait_closed()

            except asyncio.TimeoutError:
                latencies.append(float("inf"))
            except Exception as e:
                logger.debug(f"Latency test failed: {e}")
                continue

            await asyncio.sleep(0.1)

        # Filter out infinite values
        valid_latencies = [l for l in latencies if l != float("inf")]

        if not valid_latencies:
            return {"min": 0, "max": 0, "avg": 0, "jitter": 0, "packet_loss": 100.0}

        min_lat = min(valid_latencies)
        max_lat = max(valid_latencies)
        avg_lat = sum(valid_latencies) / len(valid_latencies)

        # Calculate jitter (variation in latency)
        if len(valid_latencies) > 1:
            diffs = [
                abs(valid_latencies[i] - valid_latencies[i - 1])
                for i in range(1, len(valid_latencies))
            ]
            jitter = sum(diffs) / len(diffs)
        else:
            jitter = 0

        packet_loss = ((count - len(valid_latencies)) / count) * 100

        return {
            "min": round(min_lat, 2),
            "max": round(max_lat, 2),
            "avg": round(avg_lat, 2),
            "jitter": round(jitter, 2),
            "packet_loss": round(packet_loss, 2),
        }

    # =========================================================================
    # 📈 THROUGHPUT TESTING
    # =========================================================================

    async def measure_download_speed(self) -> float:
        """Measure download speed in Mbps"""
        test_urls = [
            "https://speed.cloudflare.com/__down?bytes=10000000",
            "https://proof.ovh.net/files/10Mb.dat",
        ]

        session = await self.get_session()

        for url in test_urls:
            try:
                start = time.perf_counter()
                total_bytes = 0

                async with session.get(url) as response:
                    async for chunk in response.content.iter_chunked(8192):
                        total_bytes += len(chunk)

                end = time.perf_counter()
                duration = end - start

                # Calculate Mbps
                mbps = (total_bytes * 8) / (duration * 1_000_000)
                return round(mbps, 2)

            except Exception as e:
                logger.warning(f"Download test failed: {e}")
                continue

        return 0.0

    async def measure_upload_speed(self) -> float:
        """Measure upload speed in Mbps (simplified test)"""
        # Upload test is more complex, using simplified estimation
        # In production, you'd use a dedicated speed test server
        try:
            session = await self.get_session()

            # Generate 1MB of data
            data = b"x" * 1_000_000

            start = time.perf_counter()

            async with session.post("https://httpbin.org/post", data=data) as response:
                await response.read()

            end = time.perf_counter()
            duration = end - start

            mbps = (len(data) * 8) / (duration * 1_000_000)
            return round(mbps, 2)

        except Exception as e:
            logger.warning(f"Upload test failed: {e}")
            return 0.0

    # =========================================================================
    # 🔧 MTU DETECTION
    # =========================================================================

    def detect_mtu(self) -> int:
        """Detect MTU (Maximum Transmission Unit)"""
        try:
            # Try common MTU values
            for mtu in [1500, 1492, 1480, 1400, 1300, 1200]:
                if platform.system() == "Windows":
                    cmd = ["ping", "-f", "-l", str(mtu - 28), "-n", "1", "8.8.8.8"]
                else:
                    cmd = [
                        "ping",
                        "-M",
                        "do",
                        "-s",
                        str(mtu - 28),
                        "-c",
                        "1",
                        "8.8.8.8",
                    ]

                result = subprocess.run(cmd, capture_output=True, timeout=5)

                if result.returncode == 0:
                    return mtu
        except:
            pass

        return 1500  # Default

    # =========================================================================
    # 🌐 NAT TYPE DETECTION
    # =========================================================================

    async def detect_nat_type(self) -> str:
        """Detect NAT type (simplified)"""
        # Full NAT detection requires STUN protocol
        # This is a simplified version

        try:
            local_ip = self.get_local_ip()
            ip_info = await self.get_public_ip_info()
            public_ip = ip_info.get("public_ip", "")

            if local_ip == public_ip:
                return "No NAT (Direct)"
            elif local_ip.startswith("192.168.") or local_ip.startswith("10."):
                return "NAT (Private Network)"
            elif local_ip.startswith("172."):
                return "NAT (Private Network - Class B)"
            else:
                return "Unknown NAT"

        except:
            return "Unknown"

    # =========================================================================
    # 📊 STABILITY MEASUREMENT
    # =========================================================================

    async def measure_stability(self, duration: int = 30) -> Dict[str, Any]:
        """Measure connection stability over time"""
        samples = []
        start_time = time.time()

        while time.time() - start_time < duration:
            try:
                latency = await self.measure_latency("8.8.8.8", count=1)
                samples.append(
                    {
                        "time": time.time() - start_time,
                        "latency": latency["avg"],
                        "success": latency["packet_loss"] == 0,
                    }
                )
            except:
                samples.append(
                    {"time": time.time() - start_time, "latency": 0, "success": False}
                )

            await asyncio.sleep(1)

        successful = [s for s in samples if s["success"]]
        latencies = [s["latency"] for s in successful if s["latency"] > 0]

        if not latencies:
            return {"stability_score": 0, "samples": samples}

        avg_latency = sum(latencies) / len(latencies)
        variance = sum((l - avg_latency) ** 2 for l in latencies) / len(latencies)
        std_dev = variance**0.5

        # Calculate stability score (0-100)
        uptime_score = (len(successful) / len(samples)) * 50
        consistency_score = (
            max(0, 50 - (std_dev / avg_latency * 50)) if avg_latency > 0 else 0
        )
        stability_score = int(uptime_score + consistency_score)

        return {
            "stability_score": stability_score,
            "uptime_percent": round((len(successful) / len(samples)) * 100, 2),
            "avg_latency": round(avg_latency, 2),
            "std_deviation": round(std_dev, 2),
            "samples": samples,
        }

    # =========================================================================
    # 🔍 FULL SCAN
    # =========================================================================

    async def get_network_info(self) -> Dict[str, Any]:
        """Get comprehensive network information"""
        ip_info = await self.get_public_ip_info()

        return {
            "hostname": self.get_hostname(),
            "local_ip": self.get_local_ip(),
            "public_ip": ip_info.get("public_ip", "Unknown"),
            "gateway": self.get_gateway(),
            "dns_servers": self.get_dns_servers(),
            "country": ip_info.get("country", "Unknown"),
            "city": ip_info.get("city", "Unknown"),
            "isp": ip_info.get("isp", "Unknown"),
            "asn": ip_info.get("asn", "Unknown"),
            "org": ip_info.get("org", "Unknown"),
            "timezone": ip_info.get("timezone", "Unknown"),
            "coordinates": {
                "lat": ip_info.get("latitude", 0),
                "lon": ip_info.get("longitude", 0),
            },
        }

    async def full_scan(self) -> Dict[str, Any]:
        """Execute full network scan"""
        logger.info("Starting full network scan...")

        # Get basic info
        network_info = await self.get_network_info()

        # Measure latency to multiple endpoints
        latency_results = {}
        for endpoint in self.LATENCY_ENDPOINTS:
            latency_results[endpoint] = await self.measure_latency(endpoint, count=5)

        # Calculate average latency
        avg_latencies = [r["avg"] for r in latency_results.values() if r["avg"] > 0]
        overall_latency = (
            sum(avg_latencies) / len(avg_latencies) if avg_latencies else 0
        )

        # Speed test
        download_speed = await self.measure_download_speed()
        upload_speed = await self.measure_upload_speed()

        # MTU detection
        mtu = self.detect_mtu()

        # NAT detection
        nat_type = await self.detect_nat_type()

        # Calculate overall score
        score = self._calculate_score(overall_latency, download_speed, upload_speed)

        result = {
            **network_info,
            "latency": round(overall_latency, 2),
            "latency_details": latency_results,
            "download_mbps": download_speed,
            "upload_mbps": upload_speed,
            "mtu": mtu,
            "nat_type": nat_type,
            "overall_score": score,
            "grade": self._get_grade(score),
        }

        logger.info(f"Network scan complete. Score: {score}")
        return result

    def _calculate_score(self, latency: float, download: float, upload: float) -> int:
        """Calculate overall network score (0-100)"""
        # Latency score (lower is better)
        if latency <= 20:
            latency_score = 100
        elif latency <= 50:
            latency_score = 80
        elif latency <= 100:
            latency_score = 60
        elif latency <= 200:
            latency_score = 40
        else:
            latency_score = 20

        # Download score
        if download >= 100:
            download_score = 100
        elif download >= 50:
            download_score = 80
        elif download >= 25:
            download_score = 60
        elif download >= 10:
            download_score = 40
        else:
            download_score = 20

        # Upload score
        if upload >= 50:
            upload_score = 100
        elif upload >= 25:
            upload_score = 80
        elif upload >= 10:
            upload_score = 60
        elif upload >= 5:
            upload_score = 40
        else:
            upload_score = 20

        # Weighted average
        return int(latency_score * 0.4 + download_score * 0.4 + upload_score * 0.2)

    def _get_grade(self, score: int) -> str:
        """Convert score to letter grade"""
        if score >= 90:
            return "A+"
        elif score >= 80:
            return "A"
        elif score >= 70:
            return "B"
        elif score >= 60:
            return "C"
        elif score >= 50:
            return "D"
        else:
            return "F"
