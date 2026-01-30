#!/usr/bin/env python3
"""
🌐 Network Analyzer Pro - Advanced Network Analysis Tool
=========================================================
A comprehensive, professional, modular network analysis and optimization tool.
Runs locally on user's system for accurate real-world measurements.

Author: Network Analyzer Pro Team
Version: 1.0.0
License: MIT
"""

import asyncio
import json
import logging
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

import uvicorn
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel

# Import our modules
from modules.network_scanner import NetworkScanner
from modules.dns_analyzer import DNSAnalyzer
from modules.cdn_tester import CDNTester
from modules.protocol_benchmark import ProtocolBenchmark
from modules.port_scanner import PortScanner
from modules.global_ping import GlobalPingTester
from modules.recommendation_engine import RecommendationEngine
from modules.service_architect import ServiceArchitect

# =============================================================================
# 🔧 CONFIGURATION
# =============================================================================

APP_NAME = "Network Analyzer Pro"
APP_VERSION = "1.0.0"
HOST = "127.0.0.1"
PORT = 8080
DEBUG = True

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler("network_analyzer.log"),
    ],
)
logger = logging.getLogger(__name__)

# =============================================================================
# 🚀 FASTAPI APPLICATION
# =============================================================================

app = FastAPI(
    title=APP_NAME,
    version=APP_VERSION,
    description="Advanced Network Analysis and Optimization Tool",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
)

# CORS for local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files
frontend_path = Path(__file__).parent.parent / "frontend"
if frontend_path.exists():
    app.mount("/static", StaticFiles(directory=str(frontend_path)), name="static")

# =============================================================================
# 📊 DATA MODELS
# =============================================================================


class ScanRequest(BaseModel):
    """Request model for network scan"""

    full_scan: bool = False
    modules: list[str] = ["network", "dns", "ping"]
    timeout: int = 30
    parallel: bool = True


class DNSTestRequest(BaseModel):
    """Request model for DNS testing"""

    custom_servers: list[str] = []
    test_domains: list[str] = ["google.com", "cloudflare.com", "github.com"]
    iterations: int = 3


class PortScanRequest(BaseModel):
    """Request model for port scanning"""

    ports: list[int] = [80, 443, 8080, 22, 53]
    timeout: float = 2.0


# =============================================================================
# 🔄 GLOBAL STATE
# =============================================================================

scan_results = {}
scan_status = {"running": False, "progress": 0, "current_module": None}

# Module instances
network_scanner = NetworkScanner()
dns_analyzer = DNSAnalyzer()
cdn_tester = CDNTester()
protocol_benchmark = ProtocolBenchmark()
port_scanner = PortScanner()
global_ping = GlobalPingTester()
recommendation_engine = RecommendationEngine()
service_architect = ServiceArchitect()

# =============================================================================
# 🏠 ROUTES - MAIN
# =============================================================================


@app.get("/")
async def serve_dashboard():
    """Serve the main dashboard"""
    index_path = frontend_path / "index.html"
    if index_path.exists():
        return FileResponse(str(index_path))
    return JSONResponse(
        {
            "app": APP_NAME,
            "version": APP_VERSION,
            "status": "running",
            "dashboard": f"http://{HOST}:{PORT}",
            "api_docs": f"http://{HOST}:{PORT}/api/docs",
        }
    )


@app.get("/api/status")
async def get_status():
    """Get application status"""
    return {
        "app": APP_NAME,
        "version": APP_VERSION,
        "status": "running",
        "scan_status": scan_status,
        "timestamp": datetime.now().isoformat(),
    }


# =============================================================================
# 🔍 ROUTES - NETWORK SCANNING
# =============================================================================


@app.get("/api/network/info")
async def get_network_info():
    """Get current network information"""
    try:
        info = await network_scanner.get_network_info()
        return {"success": True, "data": info}
    except Exception as e:
        logger.error(f"Network info error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/network/public-ip")
async def get_public_ip():
    """Get public IP and geolocation"""
    try:
        data = await network_scanner.get_public_ip_info()
        return {"success": True, "data": data}
    except Exception as e:
        logger.error(f"Public IP error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/network/scan")
async def run_network_scan(request: ScanRequest, background_tasks: BackgroundTasks):
    """Run comprehensive network scan"""
    if scan_status["running"]:
        raise HTTPException(status_code=409, detail="Scan already in progress")

    background_tasks.add_task(execute_full_scan, request)
    return {
        "success": True,
        "message": "Scan started",
        "status_url": "/api/scan/status",
    }


@app.get("/api/scan/status")
async def get_scan_status():
    """Get current scan status"""
    return scan_status


@app.get("/api/scan/results")
async def get_scan_results():
    """Get latest scan results"""
    return {"success": True, "data": scan_results}


async def execute_full_scan(request: ScanRequest):
    """Execute full network scan in background"""
    global scan_status, scan_results

    scan_status = {"running": True, "progress": 0, "current_module": "initializing"}
    results = {"timestamp": datetime.now().isoformat(), "modules": {}}

    try:
        modules_to_run = (
            request.modules
            if not request.full_scan
            else ["network", "dns", "cdn", "protocol", "ports", "global_ping"]
        )
        total_modules = len(modules_to_run)

        for i, module in enumerate(modules_to_run):
            scan_status["current_module"] = module
            scan_status["progress"] = int((i / total_modules) * 100)

            if module == "network":
                results["modules"]["network"] = await network_scanner.full_scan()
            elif module == "dns":
                results["modules"]["dns"] = await dns_analyzer.benchmark_all()
            elif module == "cdn":
                results["modules"]["cdn"] = await cdn_tester.test_all()
            elif module == "protocol":
                results["modules"][
                    "protocol"
                ] = await protocol_benchmark.benchmark_all()
            elif module == "ports":
                results["modules"]["ports"] = await port_scanner.scan_common_ports()
            elif module == "global_ping":
                results["modules"]["global_ping"] = await global_ping.test_all_regions()

        # Generate recommendations
        scan_status["current_module"] = "generating_recommendations"
        results["recommendations"] = recommendation_engine.analyze(results["modules"])
        results["architecture"] = service_architect.design(results["modules"])

        scan_status["progress"] = 100
        scan_results = results

    except Exception as e:
        logger.error(f"Scan error: {e}")
        results["error"] = str(e)
    finally:
        scan_status = {"running": False, "progress": 100, "current_module": "complete"}


# =============================================================================
# 🌍 ROUTES - DNS ANALYSIS
# =============================================================================


@app.get("/api/dns/servers")
async def get_dns_servers():
    """Get list of DNS servers to test"""
    return {"success": True, "data": dns_analyzer.get_dns_list()}


@app.post("/api/dns/test")
async def test_dns(request: DNSTestRequest):
    """Test DNS servers"""
    try:
        results = await dns_analyzer.benchmark(
            custom_servers=request.custom_servers,
            test_domains=request.test_domains,
            iterations=request.iterations,
        )
        return {"success": True, "data": results}
    except Exception as e:
        logger.error(f"DNS test error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/dns/recommend")
async def get_dns_recommendations():
    """Get DNS recommendations based on tests"""
    try:
        recommendations = await dns_analyzer.get_recommendations()
        return {"success": True, "data": recommendations}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# ☁️ ROUTES - CDN TESTING
# =============================================================================


@app.get("/api/cdn/list")
async def get_cdn_list():
    """Get list of CDN providers to test"""
    return {"success": True, "data": cdn_tester.get_cdn_list()}


@app.get("/api/cdn/test")
async def test_cdns():
    """Test all CDN providers"""
    try:
        results = await cdn_tester.test_all()
        return {"success": True, "data": results}
    except Exception as e:
        logger.error(f"CDN test error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# 📡 ROUTES - PROTOCOL BENCHMARK
# =============================================================================


@app.get("/api/protocol/benchmark")
async def benchmark_protocols():
    """Benchmark different protocols"""
    try:
        results = await protocol_benchmark.benchmark_all()
        return {"success": True, "data": results}
    except Exception as e:
        logger.error(f"Protocol benchmark error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# 🔌 ROUTES - PORT SCANNING
# =============================================================================


@app.post("/api/ports/scan")
async def scan_ports(request: PortScanRequest):
    """Scan specified ports"""
    try:
        results = await port_scanner.scan(request.ports, request.timeout)
        return {"success": True, "data": results}
    except Exception as e:
        logger.error(f"Port scan error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/ports/common")
async def scan_common_ports():
    """Scan common ports"""
    try:
        results = await port_scanner.scan_common_ports()
        return {"success": True, "data": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# 🌐 ROUTES - GLOBAL PING
# =============================================================================


@app.get("/api/ping/regions")
async def get_ping_regions():
    """Get list of regions for ping testing"""
    return {"success": True, "data": global_ping.get_regions()}


@app.get("/api/ping/test")
async def test_global_ping():
    """Test latency to all regions"""
    try:
        results = await global_ping.test_all_regions()
        return {"success": True, "data": results}
    except Exception as e:
        logger.error(f"Global ping error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/ping/best-location")
async def get_best_location():
    """Get best server location recommendation"""
    try:
        results = await global_ping.test_all_regions()
        best = global_ping.get_best_location(results)
        return {"success": True, "data": best}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# 🧠 ROUTES - RECOMMENDATIONS
# =============================================================================


@app.get("/api/recommendations")
async def get_recommendations():
    """Get all recommendations based on latest scan"""
    if not scan_results:
        raise HTTPException(
            status_code=404, detail="No scan results available. Run a scan first."
        )

    return {
        "success": True,
        "data": {
            "recommendations": scan_results.get("recommendations", {}),
            "architecture": scan_results.get("architecture", {}),
        },
    }


# =============================================================================
# 📄 ROUTES - REPORTS
# =============================================================================


@app.get("/api/report/json")
async def export_json_report():
    """Export scan results as JSON"""
    if not scan_results:
        raise HTTPException(status_code=404, detail="No scan results available")

    return JSONResponse(
        content=scan_results,
        headers={"Content-Disposition": "attachment; filename=network_report.json"},
    )


@app.get("/api/report/summary")
async def get_report_summary():
    """Get summary report"""
    if not scan_results:
        raise HTTPException(status_code=404, detail="No scan results available")

    summary = {
        "timestamp": scan_results.get("timestamp"),
        "modules_tested": list(scan_results.get("modules", {}).keys()),
        "overall_score": calculate_overall_score(scan_results),
        "key_findings": extract_key_findings(scan_results),
        "top_recommendations": get_top_recommendations(scan_results),
    }
    return {"success": True, "data": summary}


def calculate_overall_score(results: dict) -> int:
    """Calculate overall network score (0-100)"""
    scores = []
    modules = results.get("modules", {})

    if "network" in modules:
        net = modules["network"]
        if net.get("latency"):
            lat_score = max(0, 100 - net["latency"])
            scores.append(lat_score)

    if "dns" in modules:
        dns = modules["dns"]
        if dns.get("best_server"):
            scores.append(dns["best_server"].get("score", 50))

    return int(sum(scores) / len(scores)) if scores else 50


def extract_key_findings(results: dict) -> list:
    """Extract key findings from results"""
    findings = []
    modules = results.get("modules", {})

    if "network" in modules:
        net = modules["network"]
        findings.append(f"Public IP: {net.get('public_ip', 'Unknown')}")
        findings.append(f"ISP: {net.get('isp', 'Unknown')}")

    return findings


def get_top_recommendations(results: dict) -> list:
    """Get top 5 recommendations"""
    recs = results.get("recommendations", {})
    return recs.get("top_5", [])


# =============================================================================
# 🚀 MAIN ENTRY POINT
# =============================================================================


def main():
    """Main entry point"""
    print(f"""
╔══════════════════════════════════════════════════════════════════╗
║                    🌐 NETWORK ANALYZER PRO                       ║
║                      Version {APP_VERSION}                              ║
╠══════════════════════════════════════════════════════════════════╣
║  Dashboard: http://{HOST}:{PORT}                               ║
║  API Docs:  http://{HOST}:{PORT}/api/docs                      ║
╚══════════════════════════════════════════════════════════════════╝
    """)

    uvicorn.run("main:app", host=HOST, port=PORT, reload=DEBUG, log_level="info")


if __name__ == "__main__":
    main()
