#!/usr/bin/env python3
"""
⚙️ Service Architect Module
===========================
Design optimal service architecture based on network analysis.
"""

from typing import Dict, List, Any
import logging

logger = logging.getLogger(__name__)

# =============================================================================
# 🔧 SERVICE ARCHITECT CLASS
# =============================================================================


class ServiceArchitect:
    """Design optimal connection architecture"""

    def design(self, results: Dict[str, Any]) -> Dict[str, Any]:
        """Design service architecture based on results"""
        architecture = {
            "recommended_type": "Standard",
            "transport_config": {},
            "network_config": {},
            "fallback_strategy": {},
            "template_configs": {},
            "compatibility_notes": [],
        }

        # Analyze network conditions
        network = results.get("network", {})
        dns = results.get("dns", {})
        ports = results.get("ports", {})

        latency = network.get("latency", 0)
        download = network.get("download_mbps", 0)
        nat_type = network.get("nat_type", "Unknown")
        open_ports = ports.get("open", [])

        # Determine architecture type
        if latency <= 50 and download >= 50:
            architecture["recommended_type"] = "High Performance"
        elif latency <= 100 and download >= 20:
            architecture["recommended_type"] = "Standard"
        elif latency <= 200:
            architecture["recommended_type"] = "Optimized for Latency"
        else:
            architecture["recommended_type"] = "Restricted Network"

        # Transport configuration
        architecture["transport_config"] = self._design_transport(
            latency, open_ports, nat_type
        )

        # Network configuration
        architecture["network_config"] = self._design_network_config(network, dns)

        # Fallback strategy
        architecture["fallback_strategy"] = self._design_fallback(open_ports)

        # Template configurations
        architecture["template_configs"] = self._generate_templates(architecture)

        # Compatibility notes
        architecture["compatibility_notes"] = self._generate_notes(results)

        return architecture

    def _design_transport(
        self, latency: float, open_ports: List[int], nat_type: str
    ) -> Dict[str, Any]:
        """Design transport layer configuration"""
        config = {
            "recommended_protocol": "TLS",
            "recommended_port": 443,
            "transport_type": "tcp",
            "multiplexing": False,
            "settings": {},
        }

        # Choose port
        if 443 in open_ports:
            config["recommended_port"] = 443
        elif 8443 in open_ports:
            config["recommended_port"] = 8443
        elif 80 in open_ports:
            config["recommended_port"] = 80
            config["recommended_protocol"] = "WebSocket"
        elif 8080 in open_ports:
            config["recommended_port"] = 8080
            config["recommended_protocol"] = "HTTP"

        # Configure for latency
        if latency > 150:
            config["multiplexing"] = True
            config["settings"]["mux_concurrency"] = 8

        # Configure for NAT
        if "NAT" in nat_type:
            config["settings"]["keepalive_interval"] = 30
            config["settings"]["idle_timeout"] = 60

        return config

    def _design_network_config(
        self, network: Dict[str, Any], dns: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Design network layer configuration"""
        config = {"mtu": 1500, "dns": [], "tcp_settings": {}, "udp_settings": {}}

        # MTU based on network
        latency = network.get("latency", 0)
        if latency > 100:
            config["mtu"] = 1400
        elif latency > 200:
            config["mtu"] = 1300

        # DNS configuration
        if dns.get("best_server"):
            config["dns"].append(dns["best_server"].get("ip", "1.1.1.1"))
        config["dns"].extend(["1.1.1.1", "8.8.8.8"])  # Fallbacks

        # TCP settings
        config["tcp_settings"] = {
            "nodelay": True,
            "keepalive": True,
            "keepalive_interval": 30,
            "buffer_size": "auto",
        }

        # Adjust for speed
        download = network.get("download_mbps", 0)
        if download >= 100:
            config["tcp_settings"]["buffer_size"] = 65536
        elif download >= 50:
            config["tcp_settings"]["buffer_size"] = 32768
        else:
            config["tcp_settings"]["buffer_size"] = 16384

        return config

    def _design_fallback(self, open_ports: List[int]) -> Dict[str, Any]:
        """Design fallback strategy"""
        fallback = {
            "enabled": True,
            "strategy": "sequential",
            "retry_interval": 30,
            "max_retries": 3,
            "fallback_chain": [],
        }

        # Build fallback chain
        port_priority = [443, 8443, 80, 8080, 2053, 2083]

        for port in port_priority:
            if port in open_ports:
                if port in [443, 8443, 2053, 2083]:
                    protocol = "tls"
                else:
                    protocol = "ws"

                fallback["fallback_chain"].append(
                    {
                        "port": port,
                        "protocol": protocol,
                        "priority": len(fallback["fallback_chain"]) + 1,
                    }
                )

        return fallback

    def _generate_templates(self, architecture: Dict[str, Any]) -> Dict[str, Any]:
        """Generate configuration templates"""
        transport = architecture.get("transport_config", {})
        network = architecture.get("network_config", {})

        templates = {
            "general": {
                "port": transport.get("recommended_port", 443),
                "protocol": transport.get("recommended_protocol", "TLS"),
                "mtu": network.get("mtu", 1500),
                "dns": network.get("dns", ["1.1.1.1"]),
                "keepalive": 30,
                "timeout": 60,
                "retry": 3,
            },
            "optimized": {
                "port": transport.get("recommended_port", 443),
                "protocol": transport.get("recommended_protocol", "TLS"),
                "mtu": network.get("mtu", 1500),
                "dns": network.get("dns", ["1.1.1.1"]),
                "keepalive": 15,
                "timeout": 30,
                "retry": 5,
                "multiplexing": transport.get("multiplexing", False),
                "mux_concurrency": transport.get("settings", {}).get(
                    "mux_concurrency", 4
                ),
                "tcp_fast_open": True,
                "tcp_nodelay": True,
            },
            "restricted_network": {
                "port": 443,
                "protocol": "TLS",
                "mtu": 1300,
                "dns": ["1.1.1.1", "8.8.8.8"],
                "keepalive": 10,
                "timeout": 20,
                "retry": 10,
                "multiplexing": True,
                "mux_concurrency": 16,
                "tcp_fast_open": False,
                "fragment": True,
                "fragment_length": "100-200",
            },
        }

        return templates

    def _generate_notes(self, results: Dict[str, Any]) -> List[str]:
        """Generate compatibility notes"""
        notes = []

        network = results.get("network", {})
        ports = results.get("ports", {})

        latency = network.get("latency", 0)
        open_ports = ports.get("open", [])

        if 443 not in open_ports:
            notes.append("⚠️ Port 443 appears blocked. Using alternative ports.")

        if latency > 200:
            notes.append("⚠️ High latency detected. Multiplexing recommended.")

        if not open_ports:
            notes.append(
                "⚠️ No common ports accessible. Network may be heavily restricted."
            )

        if 80 in open_ports and 443 not in open_ports:
            notes.append("ℹ️ Only HTTP port open. Consider WebSocket-based protocols.")

        if "NAT" in network.get("nat_type", ""):
            notes.append("ℹ️ Behind NAT. Keep-alive settings recommended.")

        return notes
