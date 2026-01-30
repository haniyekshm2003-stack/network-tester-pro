#!/usr/bin/env python3
"""
🧠 Recommendation Engine Module
===============================
Smart recommendations based on test results.
"""

from typing import Dict, List, Any
import logging

logger = logging.getLogger(__name__)

# =============================================================================
# 🔧 RECOMMENDATION ENGINE CLASS
# =============================================================================


class RecommendationEngine:
    """Generate smart recommendations from test data"""

    def analyze(self, results: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze results and generate recommendations"""
        recommendations = {
            "overall_score": 0,
            "overall_grade": "N/A",
            "network_quality": {},
            "best_dns": None,
            "best_cdn": None,
            "best_location": None,
            "best_protocol": None,
            "best_ports": [],
            "connection_strategy": {},
            "optimization_tips": [],
            "warnings": [],
            "summary": "",
        }

        scores = []

        # Analyze network results
        if "network" in results:
            net = results["network"]
            net_score = net.get("overall_score", 0)
            scores.append(net_score)

            recommendations["network_quality"] = {
                "score": net_score,
                "grade": net.get("grade", "N/A"),
                "latency": net.get("latency", 0),
                "download": net.get("download_mbps", 0),
                "upload": net.get("upload_mbps", 0),
                "isp": net.get("isp", "Unknown"),
                "nat_type": net.get("nat_type", "Unknown"),
            }

            # Tips based on network
            if net.get("latency", 0) > 100:
                recommendations["optimization_tips"].append(
                    {
                        "category": "Latency",
                        "tip": "High latency detected. Consider using a closer server or checking your connection.",
                        "priority": "high",
                    }
                )

            if net.get("download_mbps", 0) < 10:
                recommendations["optimization_tips"].append(
                    {
                        "category": "Speed",
                        "tip": "Low download speed. Check for bandwidth throttling or network congestion.",
                        "priority": "medium",
                    }
                )

        # Analyze DNS results
        if "dns" in results:
            dns = results["dns"]
            if dns.get("best_server"):
                best_dns = dns["best_server"]
                recommendations["best_dns"] = {
                    "name": best_dns.get("name", "Unknown"),
                    "ip": best_dns.get("ip", ""),
                    "latency": best_dns.get("avg_response_time", 0),
                    "score": best_dns.get("reliability_score", 0),
                    "reason": f"Fastest response time ({best_dns.get('avg_response_time', 0)}ms)",
                }
                scores.append(best_dns.get("reliability_score", 50))

        # Analyze CDN results
        if "cdn" in results:
            cdn = results["cdn"]
            if cdn.get("best_cdn"):
                best_cdn = cdn["best_cdn"]
                recommendations["best_cdn"] = {
                    "name": best_cdn.get("name", "Unknown"),
                    "latency": best_cdn.get("avg_latency", 0),
                    "score": best_cdn.get("score", 0),
                    "reason": f"Lowest latency ({best_cdn.get('avg_latency', 0)}ms)",
                }
                scores.append(best_cdn.get("score", 50))

        # Analyze global ping results
        if "global_ping" in results:
            ping = results["global_ping"]
            if ping.get("best_overall"):
                best_loc = ping["best_overall"]
                recommendations["best_location"] = {
                    "name": best_loc.get("name", "Unknown"),
                    "country": best_loc.get("country", ""),
                    "city": best_loc.get("city", ""),
                    "latency": best_loc.get("avg_latency", 0),
                    "score": best_loc.get("score", 0),
                    "reason": f"Lowest latency to {best_loc.get('city', 'Unknown')}",
                }
                scores.append(best_loc.get("score", 50))

        # Analyze protocol results
        if "protocol" in results:
            proto = results["protocol"]
            if proto.get("rankings", {}).get("recommendation"):
                rec = proto["rankings"]["recommendation"]
                recommendations["best_protocol"] = {
                    "protocol": rec.get("protocol", "https"),
                    "reason": rec.get("reason", "Best performance"),
                }

        # Analyze port results
        if "ports" in results:
            ports = results["ports"]
            open_ports = ports.get("open", [])
            recommendations["best_ports"] = self._analyze_ports(open_ports)

        # Generate connection strategy
        recommendations["connection_strategy"] = self._generate_strategy(results)

        # Calculate overall score
        if scores:
            recommendations["overall_score"] = int(sum(scores) / len(scores))
            recommendations["overall_grade"] = self._get_grade(
                recommendations["overall_score"]
            )

        # Generate summary
        recommendations["summary"] = self._generate_summary(recommendations)

        return recommendations

    def _analyze_ports(self, open_ports: List[int]) -> List[Dict[str, Any]]:
        """Analyze open ports and recommend best ones"""
        recommendations = []

        # Priority order for tunneling
        priority_ports = [
            (443, "HTTPS - Most reliable, rarely blocked"),
            (8443, "HTTPS Alt - Good alternative to 443"),
            (80, "HTTP - Widely accessible"),
            (8080, "HTTP Proxy - Common proxy port"),
        ]

        for port, reason in priority_ports:
            if port in open_ports:
                recommendations.append(
                    {"port": port, "recommended": True, "reason": reason}
                )

        return recommendations[:3]  # Top 3

    def _generate_strategy(self, results: Dict[str, Any]) -> Dict[str, Any]:
        """Generate connection strategy based on results"""
        strategy = {
            "recommended_approach": "Standard",
            "transport": "TLS",
            "port": 443,
            "fallback_ports": [8443, 80, 8080],
            "optimization": {},
            "notes": [],
        }

        # Analyze network conditions
        network = results.get("network", {})
        latency = network.get("latency", 0)

        if latency > 200:
            strategy["optimization"]["mtu"] = 1400
            strategy["optimization"]["buffer_size"] = "large"
            strategy["notes"].append("High latency - consider using multiplexing")
        else:
            strategy["optimization"]["mtu"] = 1500
            strategy["optimization"]["buffer_size"] = "normal"

        # Check port availability
        ports = results.get("ports", {})
        open_ports = ports.get("open", [])

        if 443 not in open_ports:
            if 8443 in open_ports:
                strategy["port"] = 8443
                strategy["notes"].append("Port 443 blocked, using 8443")
            elif 80 in open_ports:
                strategy["port"] = 80
                strategy["transport"] = "WebSocket"
                strategy["notes"].append("Using WebSocket over HTTP")

        # DNS strategy
        dns = results.get("dns", {})
        if dns.get("best_server"):
            strategy["recommended_dns"] = dns["best_server"].get("ip", "1.1.1.1")

        return strategy

    def _get_grade(self, score: int) -> str:
        """Convert score to grade"""
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

    def _generate_summary(self, recommendations: Dict[str, Any]) -> str:
        """Generate text summary"""
        score = recommendations.get("overall_score", 0)
        grade = recommendations.get("overall_grade", "N/A")

        summary_parts = [f"Network Score: {score}/100 (Grade {grade})."]

        if recommendations.get("best_dns"):
            dns = recommendations["best_dns"]
            summary_parts.append(f"Best DNS: {dns['name']} ({dns['latency']}ms).")

        if recommendations.get("best_location"):
            loc = recommendations["best_location"]
            summary_parts.append(
                f"Best Server Location: {loc['city']}, {loc['country']} ({loc['latency']}ms)."
            )

        if recommendations.get("best_cdn"):
            cdn = recommendations["best_cdn"]
            summary_parts.append(f"Best CDN: {cdn['name']} ({cdn['latency']}ms).")

        return " ".join(summary_parts)
