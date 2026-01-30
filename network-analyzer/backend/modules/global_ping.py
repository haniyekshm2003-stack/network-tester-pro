#!/usr/bin/env python3
"""
🌍 Global Ping Tester Module
============================
Test latency to servers worldwide for location recommendations.
"""

import asyncio
import time
from typing import Dict, List, Any
import aiohttp
import logging

logger = logging.getLogger(__name__)

# =============================================================================
# 📊 GLOBAL ENDPOINTS DATABASE
# =============================================================================

GLOBAL_ENDPOINTS = {
    # North America
    "US-East (Virginia)": {
        "endpoints": ["ec2.us-east-1.amazonaws.com", "www.google.com"],
        "region": "North America",
        "country": "United States",
        "city": "Virginia",
        "ip": "52.0.0.1",
    },
    "US-West (California)": {
        "endpoints": ["ec2.us-west-1.amazonaws.com"],
        "region": "North America",
        "country": "United States",
        "city": "California",
        "ip": "52.8.0.1",
    },
    "US-West (Oregon)": {
        "endpoints": ["ec2.us-west-2.amazonaws.com"],
        "region": "North America",
        "country": "United States",
        "city": "Oregon",
        "ip": "52.10.0.1",
    },
    "Canada (Montreal)": {
        "endpoints": ["ec2.ca-central-1.amazonaws.com"],
        "region": "North America",
        "country": "Canada",
        "city": "Montreal",
        "ip": "52.60.0.1",
    },
    # Europe
    "EU-West (Ireland)": {
        "endpoints": ["ec2.eu-west-1.amazonaws.com"],
        "region": "Europe",
        "country": "Ireland",
        "city": "Dublin",
        "ip": "52.30.0.1",
    },
    "EU-West (London)": {
        "endpoints": ["ec2.eu-west-2.amazonaws.com"],
        "region": "Europe",
        "country": "United Kingdom",
        "city": "London",
        "ip": "52.56.0.1",
    },
    "EU-West (Paris)": {
        "endpoints": ["ec2.eu-west-3.amazonaws.com"],
        "region": "Europe",
        "country": "France",
        "city": "Paris",
        "ip": "52.47.0.1",
    },
    "EU-Central (Frankfurt)": {
        "endpoints": ["ec2.eu-central-1.amazonaws.com"],
        "region": "Europe",
        "country": "Germany",
        "city": "Frankfurt",
        "ip": "52.28.0.1",
    },
    "EU-North (Stockholm)": {
        "endpoints": ["ec2.eu-north-1.amazonaws.com"],
        "region": "Europe",
        "country": "Sweden",
        "city": "Stockholm",
        "ip": "13.48.0.1",
    },
    "Netherlands (Amsterdam)": {
        "endpoints": ["speedtest.ams01.softlayer.com"],
        "region": "Europe",
        "country": "Netherlands",
        "city": "Amsterdam",
        "ip": "159.8.0.1",
    },
    # Asia Pacific
    "Asia (Tokyo)": {
        "endpoints": ["ec2.ap-northeast-1.amazonaws.com"],
        "region": "Asia Pacific",
        "country": "Japan",
        "city": "Tokyo",
        "ip": "52.68.0.1",
    },
    "Asia (Seoul)": {
        "endpoints": ["ec2.ap-northeast-2.amazonaws.com"],
        "region": "Asia Pacific",
        "country": "South Korea",
        "city": "Seoul",
        "ip": "52.78.0.1",
    },
    "Asia (Singapore)": {
        "endpoints": ["ec2.ap-southeast-1.amazonaws.com"],
        "region": "Asia Pacific",
        "country": "Singapore",
        "city": "Singapore",
        "ip": "52.74.0.1",
    },
    "Asia (Hong Kong)": {
        "endpoints": ["ec2.ap-east-1.amazonaws.com"],
        "region": "Asia Pacific",
        "country": "Hong Kong",
        "city": "Hong Kong",
        "ip": "16.162.0.1",
    },
    "Asia (Mumbai)": {
        "endpoints": ["ec2.ap-south-1.amazonaws.com"],
        "region": "Asia Pacific",
        "country": "India",
        "city": "Mumbai",
        "ip": "52.66.0.1",
    },
    "Australia (Sydney)": {
        "endpoints": ["ec2.ap-southeast-2.amazonaws.com"],
        "region": "Asia Pacific",
        "country": "Australia",
        "city": "Sydney",
        "ip": "52.62.0.1",
    },
    # Middle East
    "Middle East (Bahrain)": {
        "endpoints": ["ec2.me-south-1.amazonaws.com"],
        "region": "Middle East",
        "country": "Bahrain",
        "city": "Bahrain",
        "ip": "15.184.0.1",
    },
    "Middle East (UAE)": {
        "endpoints": ["ec2.me-central-1.amazonaws.com"],
        "region": "Middle East",
        "country": "UAE",
        "city": "Dubai",
        "ip": "3.28.0.1",
    },
    # South America
    "South America (São Paulo)": {
        "endpoints": ["ec2.sa-east-1.amazonaws.com"],
        "region": "South America",
        "country": "Brazil",
        "city": "São Paulo",
        "ip": "52.67.0.1",
    },
    # Africa
    "Africa (Cape Town)": {
        "endpoints": ["ec2.af-south-1.amazonaws.com"],
        "region": "Africa",
        "country": "South Africa",
        "city": "Cape Town",
        "ip": "13.244.0.1",
    },
}

# =============================================================================
# 🔧 GLOBAL PING TESTER CLASS
# =============================================================================


class GlobalPingTester:
    """Test latency to global locations"""

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

    def get_regions(self) -> Dict[str, Any]:
        """Get list of all regions"""
        regions = {}
        for name, info in GLOBAL_ENDPOINTS.items():
            region = info["region"]
            if region not in regions:
                regions[region] = []
            regions[region].append(
                {"name": name, "country": info["country"], "city": info["city"]}
            )
        return regions

    # =========================================================================
    # ⚡ LATENCY TESTING
    # =========================================================================

    async def test_location(self, name: str, info: Dict[str, Any]) -> Dict[str, Any]:
        """Test latency to a specific location"""
        results = {
            "name": name,
            "region": info["region"],
            "country": info["country"],
            "city": info["city"],
            "tests": [],
            "avg_latency": 0,
            "min_latency": float("inf"),
            "max_latency": 0,
            "reachable": False,
            "score": 0,
        }

        latencies = []

        for endpoint in info["endpoints"]:
            for _ in range(3):  # 3 iterations
                try:
                    start = time.perf_counter()

                    # TCP connection test
                    reader, writer = await asyncio.wait_for(
                        asyncio.open_connection(endpoint, 443), timeout=self.timeout
                    )

                    end = time.perf_counter()
                    latency = (end - start) * 1000

                    writer.close()
                    await writer.wait_closed()

                    latencies.append(latency)
                    results["min_latency"] = min(results["min_latency"], latency)
                    results["max_latency"] = max(results["max_latency"], latency)
                    results["reachable"] = True

                    results["tests"].append(
                        {
                            "endpoint": endpoint,
                            "latency_ms": round(latency, 2),
                            "success": True,
                        }
                    )

                except asyncio.TimeoutError:
                    results["tests"].append(
                        {
                            "endpoint": endpoint,
                            "latency_ms": self.timeout * 1000,
                            "success": False,
                            "error": "Timeout",
                        }
                    )
                except Exception as e:
                    results["tests"].append(
                        {
                            "endpoint": endpoint,
                            "latency_ms": 0,
                            "success": False,
                            "error": str(e),
                        }
                    )

                await asyncio.sleep(0.05)

        if latencies:
            results["avg_latency"] = round(sum(latencies) / len(latencies), 2)
            results["min_latency"] = round(results["min_latency"], 2)
            results["max_latency"] = round(results["max_latency"], 2)
            results["score"] = self._calculate_score(results["avg_latency"])
        else:
            results["min_latency"] = 0

        return results

    def _calculate_score(self, avg_latency: float) -> int:
        """Calculate location score based on latency"""
        if avg_latency <= 20:
            return 100
        elif avg_latency <= 50:
            return 90
        elif avg_latency <= 100:
            return 80
        elif avg_latency <= 150:
            return 70
        elif avg_latency <= 200:
            return 60
        elif avg_latency <= 300:
            return 50
        elif avg_latency <= 500:
            return 30
        else:
            return 10

    async def test_all_regions(self) -> Dict[str, Any]:
        """Test all global regions"""
        logger.info(f"Testing {len(GLOBAL_ENDPOINTS)} global locations...")

        # Test all locations concurrently
        tasks = [
            self.test_location(name, info) for name, info in GLOBAL_ENDPOINTS.items()
        ]

        results_list = await asyncio.gather(*tasks, return_exceptions=True)

        # Process results
        results = {}
        for result in results_list:
            if isinstance(result, dict):
                results[result["name"]] = result
            elif isinstance(result, Exception):
                logger.error(f"Location test error: {result}")

        # Sort by latency
        sorted_results = dict(
            sorted(
                results.items(),
                key=lambda x: x[1]["avg_latency"]
                if x[1]["avg_latency"] > 0
                else float("inf"),
            )
        )

        # Group by region
        by_region = {}
        for name, data in sorted_results.items():
            region = data["region"]
            if region not in by_region:
                by_region[region] = []
            by_region[region].append({"name": name, **data})

        # Find best locations
        best_overall = None
        best_per_region = {}

        if sorted_results:
            best_name = list(sorted_results.keys())[0]
            best_overall = {"name": best_name, **sorted_results[best_name]}

        for region, locations in by_region.items():
            reachable = [l for l in locations if l["reachable"]]
            if reachable:
                best_per_region[region] = reachable[0]

        # Generate rankings
        rankings = [
            {
                "rank": i + 1,
                "name": name,
                "country": data["country"],
                "city": data["city"],
                "latency": data["avg_latency"],
                "score": data["score"],
            }
            for i, (name, data) in enumerate(sorted_results.items())
            if data["reachable"]
        ]

        return {
            "locations": sorted_results,
            "by_region": by_region,
            "best_overall": best_overall,
            "best_per_region": best_per_region,
            "rankings": rankings,
            "total_tested": len(sorted_results),
            "reachable_count": len(
                [l for l in sorted_results.values() if l["reachable"]]
            ),
        }

    def get_best_location(self, results: Dict[str, Any]) -> Dict[str, Any]:
        """Get best location recommendation"""
        best = results.get("best_overall")

        if not best:
            return {"error": "No reachable locations found"}

        return {
            "recommended_location": best["name"],
            "country": best["country"],
            "city": best["city"],
            "latency_ms": best["avg_latency"],
            "score": best["score"],
            "reason": self._get_recommendation_reason(best["avg_latency"]),
            "alternatives": results.get("rankings", [])[1:4],  # Next 3 best
        }

    def _get_recommendation_reason(self, latency: float) -> str:
        """Generate recommendation reason"""
        if latency <= 20:
            return "Excellent - Very low latency, ideal for real-time applications"
        elif latency <= 50:
            return "Great - Low latency, suitable for most applications"
        elif latency <= 100:
            return "Good - Acceptable latency for general use"
        elif latency <= 200:
            return "Fair - Higher latency, may affect real-time applications"
        else:
            return "Consider - High latency, look for closer alternatives"
