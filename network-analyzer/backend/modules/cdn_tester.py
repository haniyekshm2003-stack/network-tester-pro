#!/usr/bin/env python3
"""
☁️ CDN Tester Module
====================
Test CDN providers for latency and reachability.
"""

import asyncio
import time
from typing import Dict, List, Any
import aiohttp
import logging

logger = logging.getLogger(__name__)

# =============================================================================
# 📊 CDN DATABASE
# =============================================================================

CDN_PROVIDERS = {
    "Cloudflare": {
        "test_urls": [
            "https://www.cloudflare.com/cdn-cgi/trace",
            "https://speed.cloudflare.com/",
        ],
        "edge_detection": "cf-ray",
        "description": "Global CDN with edge computing",
    },
    "Fastly": {
        "test_urls": ["https://www.fastly.com/", "https://developer.fastly.com/"],
        "edge_detection": "x-served-by",
        "description": "Edge cloud platform",
    },
    "Akamai": {
        "test_urls": [
            "https://www.akamai.com/",
        ],
        "edge_detection": "x-akamai",
        "description": "Enterprise CDN leader",
    },
    "Amazon CloudFront": {
        "test_urls": ["https://d1.awsstatic.com/", "https://aws.amazon.com/"],
        "edge_detection": "x-amz-cf",
        "description": "AWS CDN service",
    },
    "Google Cloud CDN": {
        "test_urls": ["https://cloud.google.com/", "https://www.google.com/"],
        "edge_detection": "x-goog",
        "description": "Google Cloud CDN",
    },
    "Microsoft Azure CDN": {
        "test_urls": ["https://azure.microsoft.com/", "https://docs.microsoft.com/"],
        "edge_detection": "x-azure",
        "description": "Azure CDN service",
    },
    "Bunny CDN": {
        "test_urls": [
            "https://bunny.net/",
        ],
        "edge_detection": "bunny",
        "description": "Fast and affordable CDN",
    },
    "KeyCDN": {
        "test_urls": [
            "https://www.keycdn.com/",
        ],
        "edge_detection": "keycdn",
        "description": "HTTP/2 CDN",
    },
    "StackPath": {
        "test_urls": [
            "https://www.stackpath.com/",
        ],
        "edge_detection": "stackpath",
        "description": "Edge services platform",
    },
    "jsDelivr": {
        "test_urls": [
            "https://cdn.jsdelivr.net/npm/jquery@3/dist/jquery.min.js",
        ],
        "edge_detection": "jsdelivr",
        "description": "Free CDN for open source",
    },
    "cdnjs": {
        "test_urls": [
            "https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js",
        ],
        "edge_detection": "cdnjs",
        "description": "Free JavaScript CDN",
    },
    "unpkg": {
        "test_urls": [
            "https://unpkg.com/react@18/umd/react.production.min.js",
        ],
        "edge_detection": "unpkg",
        "description": "npm CDN",
    },
}

# =============================================================================
# 🔧 CDN TESTER CLASS
# =============================================================================


class CDNTester:
    """CDN latency and reachability tester"""

    def __init__(self):
        self.timeout = 10
        self.session = None

    async def get_session(self) -> aiohttp.ClientSession:
        """Get or create aiohttp session"""
        if self.session is None or self.session.closed:
            self.session = aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=self.timeout),
                headers={"User-Agent": "NetworkAnalyzerPro/1.0"},
            )
        return self.session

    async def close(self):
        """Close session"""
        if self.session and not self.session.closed:
            await self.session.close()

    def get_cdn_list(self) -> Dict[str, Any]:
        """Get list of CDN providers"""
        return {
            name: {"description": info["description"], "test_urls": info["test_urls"]}
            for name, info in CDN_PROVIDERS.items()
        }

    # =========================================================================
    # ⚡ CDN TESTING
    # =========================================================================

    async def test_cdn(self, name: str, info: Dict[str, Any]) -> Dict[str, Any]:
        """Test a single CDN provider"""
        session = await self.get_session()

        results = {
            "name": name,
            "description": info["description"],
            "tests": [],
            "avg_latency": 0,
            "min_latency": float("inf"),
            "max_latency": 0,
            "success_rate": 0,
            "reachable": False,
            "edge_info": None,
            "score": 0,
        }

        latencies = []
        successful = 0

        for url in info["test_urls"]:
            try:
                # Multiple iterations for accuracy
                for _ in range(3):
                    start = time.perf_counter()

                    async with session.get(url, allow_redirects=True) as response:
                        await response.read()

                        end = time.perf_counter()
                        latency = (end - start) * 1000  # ms

                        # Check for edge headers
                        edge_info = None
                        for header, value in response.headers.items():
                            if info["edge_detection"].lower() in header.lower():
                                edge_info = f"{header}: {value}"
                                break

                        if response.status == 200:
                            successful += 1
                            latencies.append(latency)
                            results["min_latency"] = min(
                                results["min_latency"], latency
                            )
                            results["max_latency"] = max(
                                results["max_latency"], latency
                            )
                            results["reachable"] = True
                            if edge_info:
                                results["edge_info"] = edge_info

                        results["tests"].append(
                            {
                                "url": url,
                                "status": response.status,
                                "latency_ms": round(latency, 2),
                                "success": response.status == 200,
                            }
                        )

                    await asyncio.sleep(0.1)

            except asyncio.TimeoutError:
                results["tests"].append(
                    {
                        "url": url,
                        "status": 0,
                        "latency_ms": self.timeout * 1000,
                        "success": False,
                        "error": "Timeout",
                    }
                )
            except Exception as e:
                results["tests"].append(
                    {
                        "url": url,
                        "status": 0,
                        "latency_ms": 0,
                        "success": False,
                        "error": str(e),
                    }
                )

        # Calculate stats
        total_tests = len(info["test_urls"]) * 3
        results["success_rate"] = round((successful / total_tests) * 100, 2)

        if latencies:
            results["avg_latency"] = round(sum(latencies) / len(latencies), 2)
            results["min_latency"] = round(results["min_latency"], 2)
            results["max_latency"] = round(results["max_latency"], 2)
        else:
            results["min_latency"] = 0

        # Calculate score
        results["score"] = self._calculate_score(
            results["avg_latency"], results["success_rate"], results["reachable"]
        )

        return results

    def _calculate_score(
        self, avg_latency: float, success_rate: float, reachable: bool
    ) -> int:
        """Calculate CDN score (0-100)"""
        if not reachable:
            return 0

        # Latency score
        if avg_latency <= 50:
            latency_score = 100
        elif avg_latency <= 100:
            latency_score = 85
        elif avg_latency <= 200:
            latency_score = 70
        elif avg_latency <= 500:
            latency_score = 50
        else:
            latency_score = 30

        # Combined score
        return int(latency_score * 0.6 + success_rate * 0.4)

    async def test_all(self) -> Dict[str, Any]:
        """Test all CDN providers"""
        logger.info(f"Testing {len(CDN_PROVIDERS)} CDN providers...")

        # Test all CDNs concurrently
        tasks = [self.test_cdn(name, info) for name, info in CDN_PROVIDERS.items()]

        results_list = await asyncio.gather(*tasks, return_exceptions=True)

        # Process results
        results = {}
        for result in results_list:
            if isinstance(result, dict):
                results[result["name"]] = result
            elif isinstance(result, Exception):
                logger.error(f"CDN test error: {result}")

        # Sort by score
        sorted_results = dict(
            sorted(results.items(), key=lambda x: x[1]["score"], reverse=True)
        )

        # Find best CDN
        best_cdn = None
        if sorted_results:
            best_name = list(sorted_results.keys())[0]
            best_cdn = {"name": best_name, **sorted_results[best_name]}

        # Categorize results
        reachable = [n for n, r in sorted_results.items() if r["reachable"]]
        unreachable = [n for n, r in sorted_results.items() if not r["reachable"]]

        return {
            "cdns": sorted_results,
            "best_cdn": best_cdn,
            "total_tested": len(sorted_results),
            "reachable_count": len(reachable),
            "unreachable_count": len(unreachable),
            "reachable": reachable,
            "unreachable": unreachable,
            "rankings": [
                {
                    "rank": i + 1,
                    "name": name,
                    "score": data["score"],
                    "latency": data["avg_latency"],
                }
                for i, (name, data) in enumerate(sorted_results.items())
                if data["reachable"]
            ],
        }
