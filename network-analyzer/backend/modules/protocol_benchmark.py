#!/usr/bin/env python3
"""
📡 Protocol Benchmark Module
============================
Benchmark different network protocols.
"""

import asyncio
import time
import ssl
import socket
from typing import Dict, List, Any
import aiohttp
import logging

logger = logging.getLogger(__name__)

# =============================================================================
# 📊 PROTOCOL TEST ENDPOINTS
# =============================================================================

TEST_ENDPOINTS = {
    "http": [
        "http://httpbin.org/get",
        "http://httpstat.us/200",
    ],
    "https": [
        "https://www.google.com/",
        "https://www.cloudflare.com/",
        "https://github.com/",
        "https://api.github.com/",
    ],
    "tls_test": [
        ("www.google.com", 443),
        ("www.cloudflare.com", 443),
        ("github.com", 443),
    ],
}

# =============================================================================
# 🔧 PROTOCOL BENCHMARK CLASS
# =============================================================================


class ProtocolBenchmark:
    """Network protocol benchmarker"""

    def __init__(self):
        self.timeout = 10
        self.session = None

    async def get_session(self) -> aiohttp.ClientSession:
        """Get or create aiohttp session"""
        if self.session is None or self.session.closed:
            connector = aiohttp.TCPConnector(ssl=False, force_close=True)
            self.session = aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=self.timeout), connector=connector
            )
        return self.session

    async def close(self):
        """Close session"""
        if self.session and not self.session.closed:
            await self.session.close()

    # =========================================================================
    # 🔒 TLS HANDSHAKE TEST
    # =========================================================================

    async def test_tls_handshake(self, host: str, port: int = 443) -> Dict[str, Any]:
        """Measure TLS handshake time"""
        try:
            start = time.perf_counter()

            # Create SSL context
            context = ssl.create_default_context()

            # Measure TCP connection
            tcp_start = time.perf_counter()
            reader, writer = await asyncio.wait_for(
                asyncio.open_connection(host, port, ssl=False), timeout=self.timeout
            )
            tcp_end = time.perf_counter()
            tcp_time = (tcp_end - tcp_start) * 1000

            writer.close()
            await writer.wait_closed()

            # Measure TLS handshake
            tls_start = time.perf_counter()
            reader, writer = await asyncio.wait_for(
                asyncio.open_connection(host, port, ssl=context), timeout=self.timeout
            )
            tls_end = time.perf_counter()

            # Get SSL info
            ssl_object = writer.get_extra_info("ssl_object")
            tls_version = ssl_object.version() if ssl_object else "Unknown"
            cipher = ssl_object.cipher() if ssl_object else None

            writer.close()
            await writer.wait_closed()

            total_time = (tls_end - start) * 1000
            tls_time = (tls_end - tls_start) * 1000

            return {
                "success": True,
                "host": host,
                "port": port,
                "tcp_time_ms": round(tcp_time, 2),
                "tls_time_ms": round(tls_time, 2),
                "total_time_ms": round(total_time, 2),
                "tls_version": tls_version,
                "cipher": cipher[0] if cipher else "Unknown",
                "cipher_bits": cipher[2] if cipher else 0,
            }

        except asyncio.TimeoutError:
            return {"success": False, "host": host, "port": port, "error": "Timeout"}
        except Exception as e:
            return {"success": False, "host": host, "port": port, "error": str(e)}

    # =========================================================================
    # 🌐 HTTP/HTTPS TEST
    # =========================================================================

    async def test_http(self, url: str, iterations: int = 3) -> Dict[str, Any]:
        """Test HTTP/HTTPS performance"""
        results = {
            "url": url,
            "protocol": "https" if url.startswith("https") else "http",
            "tests": [],
            "avg_time": 0,
            "min_time": float("inf"),
            "max_time": 0,
            "success_rate": 0,
        }

        times = []
        successful = 0

        # Create fresh session for each test
        connector = aiohttp.TCPConnector(force_close=True)
        timeout = aiohttp.ClientTimeout(total=self.timeout)

        async with aiohttp.ClientSession(
            connector=connector, timeout=timeout
        ) as session:
            for i in range(iterations):
                try:
                    start = time.perf_counter()

                    async with session.get(url) as response:
                        await response.read()

                        end = time.perf_counter()
                        elapsed = (end - start) * 1000

                        if response.status == 200:
                            successful += 1
                            times.append(elapsed)
                            results["min_time"] = min(results["min_time"], elapsed)
                            results["max_time"] = max(results["max_time"], elapsed)

                        results["tests"].append(
                            {
                                "iteration": i + 1,
                                "status": response.status,
                                "time_ms": round(elapsed, 2),
                                "success": response.status == 200,
                            }
                        )

                except Exception as e:
                    results["tests"].append(
                        {
                            "iteration": i + 1,
                            "status": 0,
                            "time_ms": 0,
                            "success": False,
                            "error": str(e),
                        }
                    )

                await asyncio.sleep(0.1)

        results["success_rate"] = round((successful / iterations) * 100, 2)

        if times:
            results["avg_time"] = round(sum(times) / len(times), 2)
            results["min_time"] = round(results["min_time"], 2)
            results["max_time"] = round(results["max_time"], 2)
        else:
            results["min_time"] = 0

        return results

    # =========================================================================
    # 📦 TCP TEST
    # =========================================================================

    async def test_tcp(
        self, host: str, port: int, iterations: int = 5
    ) -> Dict[str, Any]:
        """Test TCP connection performance"""
        results = {
            "host": host,
            "port": port,
            "protocol": "tcp",
            "tests": [],
            "avg_time": 0,
            "min_time": float("inf"),
            "max_time": 0,
            "success_rate": 0,
        }

        times = []
        successful = 0

        for i in range(iterations):
            try:
                start = time.perf_counter()

                reader, writer = await asyncio.wait_for(
                    asyncio.open_connection(host, port), timeout=self.timeout
                )

                end = time.perf_counter()
                elapsed = (end - start) * 1000

                writer.close()
                await writer.wait_closed()

                successful += 1
                times.append(elapsed)
                results["min_time"] = min(results["min_time"], elapsed)
                results["max_time"] = max(results["max_time"], elapsed)

                results["tests"].append(
                    {"iteration": i + 1, "time_ms": round(elapsed, 2), "success": True}
                )

            except asyncio.TimeoutError:
                results["tests"].append(
                    {
                        "iteration": i + 1,
                        "time_ms": self.timeout * 1000,
                        "success": False,
                        "error": "Timeout",
                    }
                )
            except Exception as e:
                results["tests"].append(
                    {
                        "iteration": i + 1,
                        "time_ms": 0,
                        "success": False,
                        "error": str(e),
                    }
                )

            await asyncio.sleep(0.05)

        results["success_rate"] = round((successful / iterations) * 100, 2)

        if times:
            results["avg_time"] = round(sum(times) / len(times), 2)
            results["min_time"] = round(results["min_time"], 2)
            results["max_time"] = round(results["max_time"], 2)
        else:
            results["min_time"] = 0

        return results

    # =========================================================================
    # 📊 FULL BENCHMARK
    # =========================================================================

    async def benchmark_all(self) -> Dict[str, Any]:
        """Run comprehensive protocol benchmark"""
        logger.info("Starting protocol benchmark...")

        results = {
            "http": [],
            "https": [],
            "tls": [],
            "tcp": [],
            "summary": {},
            "rankings": {},
        }

        # Test HTTP
        for url in TEST_ENDPOINTS["http"]:
            result = await self.test_http(url)
            results["http"].append(result)

        # Test HTTPS
        for url in TEST_ENDPOINTS["https"]:
            result = await self.test_http(url)
            results["https"].append(result)

        # Test TLS handshake
        for host, port in TEST_ENDPOINTS["tls_test"]:
            result = await self.test_tls_handshake(host, port)
            results["tls"].append(result)

        # Test TCP
        tcp_tests = [
            ("google.com", 80),
            ("cloudflare.com", 80),
            ("github.com", 443),
        ]
        for host, port in tcp_tests:
            result = await self.test_tcp(host, port)
            results["tcp"].append(result)

        # Calculate summary
        results["summary"] = self._calculate_summary(results)
        results["rankings"] = self._generate_rankings(results)

        return results

    def _calculate_summary(self, results: Dict[str, Any]) -> Dict[str, Any]:
        """Calculate benchmark summary"""
        summary = {}

        for protocol in ["http", "https", "tcp"]:
            if results[protocol]:
                times = [
                    r["avg_time"] for r in results[protocol] if r.get("avg_time", 0) > 0
                ]
                success_rates = [r["success_rate"] for r in results[protocol]]

                summary[protocol] = {
                    "avg_latency": round(sum(times) / len(times), 2) if times else 0,
                    "avg_success_rate": round(
                        sum(success_rates) / len(success_rates), 2
                    )
                    if success_rates
                    else 0,
                    "tests_count": len(results[protocol]),
                }

        # TLS summary
        if results["tls"]:
            tls_times = [
                r["tls_time_ms"] for r in results["tls"] if r.get("success", False)
            ]
            summary["tls"] = {
                "avg_handshake_time": round(sum(tls_times) / len(tls_times), 2)
                if tls_times
                else 0,
                "tests_count": len(results["tls"]),
            }

        return summary

    def _generate_rankings(self, results: Dict[str, Any]) -> Dict[str, Any]:
        """Generate protocol rankings"""
        rankings = {"by_speed": [], "by_reliability": [], "recommendation": None}

        protocol_scores = []

        for protocol in ["http", "https", "tcp"]:
            if protocol in results["summary"]:
                data = results["summary"][protocol]
                latency = data.get("avg_latency", 999)
                success = data.get("avg_success_rate", 0)

                # Calculate score
                speed_score = max(0, 100 - latency)
                reliability_score = success
                combined_score = speed_score * 0.4 + reliability_score * 0.6

                protocol_scores.append(
                    {
                        "protocol": protocol,
                        "latency": latency,
                        "success_rate": success,
                        "speed_score": round(speed_score, 2),
                        "reliability_score": round(reliability_score, 2),
                        "combined_score": round(combined_score, 2),
                    }
                )

        # Sort by speed
        rankings["by_speed"] = sorted(protocol_scores, key=lambda x: x["latency"])

        # Sort by reliability
        rankings["by_reliability"] = sorted(
            protocol_scores, key=lambda x: x["reliability_score"], reverse=True
        )

        # Best recommendation
        if protocol_scores:
            best = max(protocol_scores, key=lambda x: x["combined_score"])
            rankings["recommendation"] = {
                "protocol": best["protocol"],
                "reason": f"Best combined score ({best['combined_score']})",
            }

        return rankings
