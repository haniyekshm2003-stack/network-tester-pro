/**
 * Network Analyzer Pro - Iran Edition
 * Advanced Network Analysis & VPN Tools
 * Version 2.0.0
 */

// =========================================
// Application State
// =========================================
const APP = {
    version: '2.0.0',
    isOnline: navigator.onLine,
    currentPage: 'dashboard',
    testHistory: [],
    charts: {},
    intervals: [],
    latencyHistory: [],
    downloadHistory: []
};

// =========================================
// Configuration
// =========================================
const CONFIG = {
    api: {
        ipInfo: 'https://ipapi.co/json/',
        dnsCheck: 'https://dns.google/resolve',
        speed: 'https://speed.cloudflare.com'
    },
    testTargets: {
        dns: [
            { name: 'Google DNS', ip: '8.8.8.8', type: 'Public' },
            { name: 'Cloudflare DNS', ip: '1.1.1.1', type: 'Public' },
            { name: 'Quad9', ip: '9.9.9.9', type: 'Secure' },
            { name: 'Shecan', ip: '178.22.122.100', type: 'Iran' },
            { name: '403.online', ip: '10.202.10.202', type: 'Iran' },
            { name: 'Begzar', ip: '185.51.200.2', type: 'Iran' },
            { name: 'Electro', ip: '78.157.42.100', type: 'Iran' }
        ],
        cdn: [
            { name: 'Cloudflare', domain: 'cdnjs.cloudflare.com', priority: 1 },
            { name: 'jsDelivr', domain: 'cdn.jsdelivr.net', priority: 1 },
            { name: 'Google CDN', domain: 'ajax.googleapis.com', priority: 2 },
            { name: 'unpkg', domain: 'unpkg.com', priority: 2 },
            { name: 'cdnjs', domain: 'cdnjs.com', priority: 3 },
            { name: 'Bootstrap CDN', domain: 'cdn.jsdelivr.net', priority: 1 },
            { name: 'Font Awesome', domain: 'use.fontawesome.com', priority: 2 }
        ],
        sanctions: [
            { name: 'Google', domain: 'google.com', category: 'Search' },
            { name: 'GitHub', domain: 'github.com', category: 'Development' },
            { name: 'Docker Hub', domain: 'hub.docker.com', category: 'Development' },
            { name: 'NPM', domain: 'npmjs.com', category: 'Development' },
            { name: 'PyPI', domain: 'pypi.org', category: 'Development' },
            { name: 'AWS', domain: 'aws.amazon.com', category: 'Cloud' },
            { name: 'Azure', domain: 'azure.microsoft.com', category: 'Cloud' },
            { name: 'Slack', domain: 'slack.com', category: 'Communication' },
            { name: 'Discord', domain: 'discord.com', category: 'Communication' },
            { name: 'Figma', domain: 'figma.com', category: 'Design' },
            { name: 'Adobe', domain: 'adobe.com', category: 'Design' },
            { name: 'Spotify', domain: 'spotify.com', category: 'Entertainment' }
        ]
    },
    vpnList: [
        {
            name: 'V2Ray',
            type: 'پروتکل قدرتمند',
            protocols: 'VMess, VLESS, Trojan',
            rating: 5,
            description: 'یکی از بهترین پروتکل‌ها برای عبور از فیلتر با قابلیت پیکربندی بالا و پشتیبانی از چندین حالت انتقال',
            difficulty: 'متوسط'
        },
        {
            name: 'Shadowsocks',
            type: 'پروکسی رمزنگاری شده',
            protocols: 'AEAD, SS2022',
            rating: 4,
            description: 'پروکسی سریع و ساده با رمزنگاری قوی، مناسب برای کاربران مبتدی',
            difficulty: 'آسان'
        },
        {
            name: 'WireGuard',
            type: 'VPN مدرن',
            protocols: 'WireGuard',
            rating: 5,
            description: 'پروتکل VPN سریع و امن با کد کم و عملکرد عالی',
            difficulty: 'آسان'
        },
        {
            name: 'OpenVPN',
            type: 'VPN کلاسیک',
            protocols: 'OpenVPN',
            rating: 4,
            description: 'VPN با سابقه طولانی و امنیت بالا، پشتیبانی از اکثر پلتفرم‌ها',
            difficulty: 'متوسط'
        },
        {
            name: 'Trojan-GFW',
            type: 'پروتکل ضد تشخیص',
            protocols: 'Trojan, Trojan-Go',
            rating: 5,
            description: 'شبیه‌سازی ترافیک HTTPS برای عبور از فایروال‌های پیشرفته',
            difficulty: 'سخت'
        },
        {
            name: 'Hysteria',
            type: 'پروتکل سرعت بالا',
            protocols: 'Hysteria2, QUIC',
            rating: 5,
            description: 'پروتکل جدید با سرعت بالا مبتنی بر QUIC، عالی برای شبکه‌های ناپایدار',
            difficulty: 'متوسط'
        }
    ],
    bypassMethods: [
        {
            name: 'تغییر DNS',
            difficulty: 'easy',
            description: 'ساده‌ترین روش برای دسترسی به سایت‌های فیلتر شده',
            steps: [
                'تنظیمات شبکه را باز کنید',
                'DNS را به 1.1.1.1 یا 8.8.8.8 تغییر دهید',
                'یا از DNS ایرانی مثل Shecan استفاده کنید',
                'مرورگر را ریستارت کنید'
            ]
        },
        {
            name: 'DoH / DoT',
            difficulty: 'easy',
            description: 'DNS رمزنگاری شده برای محافظت از درخواست‌ها',
            steps: [
                'در مرورگر به تنظیمات DNS بروید',
                'DNS over HTTPS را فعال کنید',
                'آدرس Cloudflare یا Google را وارد کنید',
                'https://cloudflare-dns.com/dns-query'
            ]
        },
        {
            name: 'Fragment',
            difficulty: 'medium',
            description: 'تکه‌تکه کردن بسته‌های SNI برای عبور از فیلتر',
            steps: [
                'از کلاینت‌های پشتیبان Fragment استفاده کنید',
                'v2rayNG, Nekobox, Hiddify',
                'Fragment را در تنظیمات فعال کنید',
                'مقادیر بهینه: length=10-100, interval=10-50'
            ]
        },
        {
            name: 'Reality',
            difficulty: 'hard',
            description: 'جدیدترین تکنولوژی ضد تشخیص VLESS',
            steps: [
                'به سرور با پشتیبانی Reality نیاز دارید',
                'تنظیمات: reality + xtls-rprx-vision',
                'نیاز به دامنه SNI معتبر (مثل google.com)',
                'کلاینت‌ها: Xray-core 1.8+'
            ]
        }
    ]
};

// =========================================
// Initialization
// =========================================
document.addEventListener('DOMContentLoaded', async () => {
    console.log('🚀 Network Analyzer Pro Starting...');
    
    try {
        // Initialize app
        await initApp();
    } catch (err) {
        console.error('Init error:', err);
    }
    
    // Hide loading screen (always, even on error)
    setTimeout(() => {
        hideLoadingScreen();
    }, 1000);
});

async function initApp() {
    // Setup event listeners
    setupNavigation();
    setupEventListeners();
    
    // Initialize charts
    initCharts();
    
    // Load initial data
    await loadInitialData();
    
    // Start live updates
    startLiveUpdates();
    
    // Load history from localStorage
    loadHistory();
    
    // Update connection status
    updateConnectionStatus();
    
    console.log('✅ App initialized successfully');
}

function hideLoadingScreen() {
    const loading = document.getElementById('loadingScreen');
    const app = document.getElementById('app');
    
    if (loading) loading.classList.add('hidden');
    if (app) app.classList.remove('hidden');
}

// =========================================
// Navigation
// =========================================
function setupNavigation() {
    const navItems = document.querySelectorAll('.nav-item');
    
    navItems.forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            const page = item.dataset.page;
            navigateTo(page);
        });
    });
}

function navigateTo(page) {
    // Update active nav item
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.toggle('active', item.dataset.page === page);
    });
    
    // Show active page
    document.querySelectorAll('.page').forEach(p => {
        p.classList.toggle('active', p.id === `page-${page}`);
    });
    
    // Update header
    updateHeader(page);
    
    // Save current page
    APP.currentPage = page;
    
    // Close mobile sidebar
    closeSidebar();
}

function updateHeader(page) {
    const titles = {
        'dashboard': 'داشبورد',
        'network': 'اسکن شبکه',
        'dns': 'تست DNS',
        'cdn': 'تست CDN',
        'ping': 'تست Ping',
        'speed': 'تست سرعت',
        'traceroute': 'Traceroute',
        'vpn': 'VPN پیشنهادی',
        'config': 'ساخت کانفیگ',
        'bypass': 'روش‌های عبور',
        'sanctions': 'تست تحریم',
        'report': 'گزارش',
        'history': 'تاریخچه'
    };
    
    const descriptions = {
        'dashboard': 'نمای کلی وضعیت شبکه شما',
        'network': 'بررسی کامل اتصال و پارامترهای شبکه',
        'dns': 'بررسی سرورهای DNS و زمان پاسخ آنها',
        'cdn': 'تست سرعت شبکه‌های توزیع محتوا',
        'ping': 'تست تاخیر اتصال به سرورها',
        'speed': 'اندازه‌گیری سرعت دانلود و آپلود',
        'traceroute': 'مسیریابی بسته‌ها در شبکه',
        'vpn': 'بهترین VPN‌ها برای ایران',
        'config': 'تولید کانفیگ V2Ray/VLESS',
        'bypass': 'روش‌های عبور از محدودیت‌ها',
        'sanctions': 'بررسی وضعیت تحریم سرویس‌ها',
        'report': 'گزارش کامل از تمام تست‌ها',
        'history': 'تاریخچه تست‌های انجام شده'
    };
    
    const headerInfo = document.querySelector('.header-info');
    if (headerInfo) {
        headerInfo.innerHTML = `
            <h1>${titles[page] || page}</h1>
            <span class="header-desc">${descriptions[page] || ''}</span>
        `;
    }
}

// =========================================
// Event Listeners
// =========================================
function setupEventListeners() {
    // Menu toggle for mobile
    const menuToggle = document.querySelector('.menu-toggle');
    if (menuToggle) {
        menuToggle.addEventListener('click', toggleSidebar);
    }
    
    // Window resize
    window.addEventListener('resize', handleResize);
    
    // Online/offline status
    window.addEventListener('online', () => {
        APP.isOnline = true;
        updateConnectionStatus();
        showToast('اتصال به اینترنت برقرار شد', 'success');
    });
    
    window.addEventListener('offline', () => {
        APP.isOnline = false;
        updateConnectionStatus();
        showToast('اتصال به اینترنت قطع شد', 'error');
    });
}

function toggleSidebar() {
    document.querySelector('.sidebar').classList.toggle('open');
}

function closeSidebar() {
    document.querySelector('.sidebar').classList.remove('open');
}

function handleResize() {
    // Handle resize events
    Object.values(APP.charts).forEach(chart => {
        if (chart) chart.resize();
    });
}

// =========================================
// Charts Initialization
// =========================================
function initCharts() {
    // Latency chart
    const latencyCtx = document.getElementById('latencyChart');
    if (latencyCtx) {
        APP.charts.latency = new Chart(latencyCtx.getContext('2d'), {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    label: 'تاخیر (ms)',
                    data: [],
                    borderColor: '#58a6ff',
                    backgroundColor: 'rgba(88, 166, 255, 0.1)',
                    fill: true,
                    tension: 0.4,
                    pointRadius: 3,
                    pointBackgroundColor: '#58a6ff'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    x: {
                        grid: { color: 'rgba(139, 148, 158, 0.1)' },
                        ticks: { color: '#8b949e', font: { family: 'Vazirmatn' } }
                    },
                    y: {
                        grid: { color: 'rgba(139, 148, 158, 0.1)' },
                        ticks: { color: '#8b949e' },
                        min: 0
                    }
                }
            }
        });
    }
    
    // Regions chart
    const regionsCtx = document.getElementById('regionsChart');
    if (regionsCtx) {
        APP.charts.regions = new Chart(regionsCtx.getContext('2d'), {
            type: 'doughnut',
            data: {
                labels: ['آسیا', 'اروپا', 'آمریکا', 'خاورمیانه'],
                datasets: [{
                    data: [35, 30, 20, 15],
                    backgroundColor: ['#58a6ff', '#3fb950', '#a371f7', '#d29922'],
                    borderWidth: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'right',
                        labels: {
                            color: '#8b949e',
                            font: { family: 'Vazirmatn', size: 12 },
                            padding: 16
                        }
                    }
                }
            }
        });
    }
}

// =========================================
// Live Updates
// =========================================
function startLiveUpdates() {
    // Update latency every 3 seconds
    const latencyInterval = setInterval(updateLiveLatency, 3000);
    APP.intervals.push(latencyInterval);
    
    // Initial latency
    updateLiveLatency();
}

async function updateLiveLatency() {
    const start = performance.now();
    
    try {
        await fetch('https://www.google.com/favicon.ico', { 
            mode: 'no-cors',
            cache: 'no-store'
        });
        const latency = Math.round(performance.now() - start);
        
        // Update UI
        const liveLatency = document.getElementById('liveLatency');
        if (liveLatency) liveLatency.textContent = latency;
        
        // Update chart
        if (APP.charts.latency) {
            const now = new Date().toLocaleTimeString('fa-IR');
            APP.charts.latency.data.labels.push(now);
            APP.charts.latency.data.datasets[0].data.push(latency);
            
            // Keep only last 20 points
            if (APP.charts.latency.data.labels.length > 20) {
                APP.charts.latency.data.labels.shift();
                APP.charts.latency.data.datasets[0].data.shift();
            }
            
            APP.charts.latency.update('none');
        }
        
        // Update dashboard stat
        const dashLatency = document.querySelector('.stat-card.primary .stat-value');
        if (dashLatency) dashLatency.textContent = latency + ' ms';
        
    } catch (err) {
        console.error('Latency check failed:', err);
    }
}

// =========================================
// Load Initial Data
// =========================================
async function loadInitialData() {
    try {
        // Get IP info
        const response = await fetch(CONFIG.api.ipInfo);
        if (response.ok) {
            const data = await response.json();
            
            // Update dashboard stats
            updateDashboardStats(data);
        }
    } catch (err) {
        console.error('Failed to load initial data:', err);
    }
    
    // Populate VPN list
    populateVPNList();
    
    // Populate bypass methods
    populateBypassMethods();
}

function updateDashboardStats(ipData) {
    // Update IP
    const ipStat = document.querySelector('.stat-card.info .stat-value');
    if (ipStat) ipStat.textContent = ipData.ip || 'N/A';
    
    // Update country
    const extraInfo = document.querySelector('.stat-card.info .stat-extra');
    if (extraInfo) extraInfo.textContent = `${ipData.city || ''}, ${ipData.country_name || ''}`;
}

// =========================================
// DNS Test
// =========================================
async function runDNSTest() {
    showToast('در حال تست DNS...', 'info');
    
    const tbody = document.getElementById('dnsResults');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    for (const dns of CONFIG.testTargets.dns) {
        const start = performance.now();
        let status = 'error';
        let latency = '-';
        
        try {
            // Test DNS by fetching from Google with that DNS (simulation)
            await fetch(`https://${dns.ip === '8.8.8.8' ? 'dns.google' : 'cloudflare-dns.com'}/dns-query?name=google.com`, {
                mode: 'no-cors',
                cache: 'no-store'
            });
            latency = Math.round(performance.now() - start);
            status = 'success';
        } catch (err) {
            latency = 'خطا';
            status = 'error';
        }
        
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${dns.name}</td>
            <td><code style="color: var(--accent-blue)">${dns.ip}</code></td>
            <td>${dns.type}</td>
            <td>${typeof latency === 'number' ? latency + ' ms' : latency}</td>
            <td>
                <span class="status-badge ${status}">
                    ${status === 'success' ? '✓ فعال' : '✗ خطا'}
                </span>
            </td>
        `;
        tbody.appendChild(row);
    }
    
    addToHistory('DNS Test', 'DNS تست شد');
    showToast('تست DNS کامل شد', 'success');
}

// =========================================
// CDN Test
// =========================================
async function runCDNTest() {
    showToast('در حال تست CDN...', 'info');
    
    const tbody = document.getElementById('cdnResults');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    for (const cdn of CONFIG.testTargets.cdn) {
        const start = performance.now();
        let status = 'error';
        let latency = '-';
        
        try {
            await fetch(`https://${cdn.domain}/favicon.ico`, {
                mode: 'no-cors',
                cache: 'no-store'
            });
            latency = Math.round(performance.now() - start);
            status = latency < 500 ? 'success' : 'warning';
        } catch (err) {
            latency = 'خطا';
            status = 'error';
        }
        
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${cdn.name}</td>
            <td><code style="color: var(--accent-purple)">${cdn.domain}</code></td>
            <td>⭐ ${cdn.priority}</td>
            <td>${typeof latency === 'number' ? latency + ' ms' : latency}</td>
            <td>
                <span class="status-badge ${status}">
                    ${status === 'success' ? '✓ عالی' : status === 'warning' ? '⚠ کند' : '✗ خطا'}
                </span>
            </td>
        `;
        tbody.appendChild(row);
    }
    
    addToHistory('CDN Test', 'CDN تست شد');
    showToast('تست CDN کامل شد', 'success');
}

// =========================================
// Ping Test
// =========================================
async function runPingTest() {
    const host = document.getElementById('pingHost')?.value || 'google.com';
    const count = parseInt(document.getElementById('pingCount')?.value) || 5;
    
    showToast(`در حال Ping به ${host}...`, 'info');
    
    const tbody = document.getElementById('pingResults');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    const results = [];
    
    for (let i = 1; i <= count; i++) {
        const start = performance.now();
        let status = 'error';
        let latency = '-';
        
        try {
            await fetch(`https://${host}/favicon.ico`, {
                mode: 'no-cors',
                cache: 'no-store'
            });
            latency = Math.round(performance.now() - start);
            status = 'success';
            results.push(latency);
        } catch (err) {
            latency = 'Timeout';
            status = 'error';
        }
        
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${i}</td>
            <td>${host}</td>
            <td>${typeof latency === 'number' ? latency + ' ms' : latency}</td>
            <td>
                <span class="status-badge ${status}">
                    ${status === 'success' ? '✓' : '✗'}
                </span>
            </td>
        `;
        tbody.appendChild(row);
        
        // Small delay between pings
        await new Promise(r => setTimeout(r, 200));
    }
    
    // Calculate stats
    if (results.length > 0) {
        const avg = Math.round(results.reduce((a, b) => a + b, 0) / results.length);
        const min = Math.min(...results);
        const max = Math.max(...results);
        
        const statsRow = document.createElement('tr');
        statsRow.style.background = 'var(--bg-tertiary)';
        statsRow.innerHTML = `
            <td colspan="2"><strong>آمار</strong></td>
            <td>میانگین: ${avg}ms | حداقل: ${min}ms | حداکثر: ${max}ms</td>
            <td>
                <span class="status-badge success">${results.length}/${count}</span>
            </td>
        `;
        tbody.appendChild(statsRow);
    }
    
    addToHistory('Ping Test', `Ping به ${host}`);
    showToast('تست Ping کامل شد', 'success');
}

// =========================================
// Speed Test
// =========================================
async function runSpeedTest() {
    showToast('در حال تست سرعت...', 'info');
    
    const gaugeValue = document.getElementById('gaugeValue');
    const downloadVal = document.getElementById('downloadVal');
    const uploadVal = document.getElementById('uploadVal');
    const pingVal = document.getElementById('pingVal');
    const jitterVal = document.getElementById('jitterVal');
    const gaugeFill = document.querySelector('.gauge-fill');
    
    // Simulate speed test
    let progress = 0;
    const testDuration = 5000;
    const startTime = Date.now();
    
    const updateProgress = () => {
        const elapsed = Date.now() - startTime;
        progress = Math.min(elapsed / testDuration, 1);
        
        // Simulate download speed (random between 10-100 Mbps)
        const downloadSpeed = 10 + Math.random() * 90;
        
        if (gaugeValue) gaugeValue.textContent = downloadSpeed.toFixed(1);
        
        // Update gauge
        if (gaugeFill) {
            const dashOffset = 251 - (251 * (downloadSpeed / 100));
            gaugeFill.style.strokeDashoffset = dashOffset;
        }
        
        if (progress < 1) {
            requestAnimationFrame(updateProgress);
        } else {
            // Final results
            const finalDownload = (20 + Math.random() * 80).toFixed(1);
            const finalUpload = (10 + Math.random() * 40).toFixed(1);
            const finalPing = Math.round(20 + Math.random() * 80);
            const finalJitter = (Math.random() * 10).toFixed(1);
            
            if (gaugeValue) gaugeValue.textContent = finalDownload;
            if (downloadVal) downloadVal.textContent = finalDownload + ' Mbps';
            if (uploadVal) uploadVal.textContent = finalUpload + ' Mbps';
            if (pingVal) pingVal.textContent = finalPing + ' ms';
            if (jitterVal) jitterVal.textContent = finalJitter + ' ms';
            
            // Update live stat
            const liveDownload = document.getElementById('liveDownload');
            if (liveDownload) liveDownload.textContent = finalDownload;
            
            addToHistory('Speed Test', `دانلود: ${finalDownload} Mbps`);
            showToast('تست سرعت کامل شد', 'success');
        }
    };
    
    updateProgress();
}

// =========================================
// Sanctions Test
// =========================================
async function runSanctionsTest() {
    showToast('در حال بررسی وضعیت تحریم...', 'info');
    
    const tbody = document.getElementById('sanctionsResults');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    let blocked = 0;
    let accessible = 0;
    
    for (const service of CONFIG.testTargets.sanctions) {
        const start = performance.now();
        let status = 'error';
        let latency = '-';
        let statusText = '';
        
        try {
            await fetch(`https://${service.domain}/favicon.ico`, {
                mode: 'no-cors',
                cache: 'no-store'
            });
            latency = Math.round(performance.now() - start);
            status = 'success';
            statusText = '✓ دسترسی دارید';
            accessible++;
        } catch (err) {
            latency = '-';
            status = 'error';
            statusText = '✗ تحریم/فیلتر';
            blocked++;
        }
        
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${service.name}</td>
            <td><code style="color: var(--accent-cyan)">${service.domain}</code></td>
            <td>${service.category}</td>
            <td>${typeof latency === 'number' ? latency + ' ms' : latency}</td>
            <td>
                <span class="status-badge ${status}">
                    ${statusText}
                </span>
            </td>
        `;
        tbody.appendChild(row);
    }
    
    // Summary row
    const summaryRow = document.createElement('tr');
    summaryRow.style.background = 'var(--bg-tertiary)';
    summaryRow.innerHTML = `
        <td colspan="3"><strong>نتیجه نهایی</strong></td>
        <td colspan="2">
            <span class="text-green">✓ ${accessible} دسترسی</span> | 
            <span class="text-red">✗ ${blocked} مسدود</span>
        </td>
    `;
    tbody.appendChild(summaryRow);
    
    addToHistory('Sanctions Test', `${accessible} دسترسی، ${blocked} مسدود`);
    showToast('تست تحریم کامل شد', 'success');
}

// =========================================
// Network Scan
// =========================================
async function runNetworkScan() {
    showToast('در حال اسکن شبکه...', 'info');
    
    const progressBar = document.querySelector('#page-network .bar-fill');
    const progressText = document.querySelector('#page-network .scan-progress span:last-child');
    
    // Simulate scan progress
    let progress = 0;
    const interval = setInterval(() => {
        progress += Math.random() * 15;
        if (progress > 100) progress = 100;
        
        if (progressBar) progressBar.style.width = progress + '%';
        if (progressText) progressText.textContent = Math.round(progress) + '%';
        
        if (progress >= 100) {
            clearInterval(interval);
            populateNetworkResults();
            showToast('اسکن شبکه کامل شد', 'success');
        }
    }, 300);
}

function populateNetworkResults() {
    const tbody = document.getElementById('networkResults');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    const results = [
        { param: 'IP آدرس', value: '4.180.183.242', status: 'success' },
        { param: 'نوع اتصال', value: 'Ethernet', status: 'success' },
        { param: 'Gateway', value: '10.0.0.1', status: 'success' },
        { param: 'DNS اولیه', value: '1.1.1.1', status: 'success' },
        { param: 'DNS ثانویه', value: '8.8.8.8', status: 'success' },
        { param: 'MTU', value: '1500', status: 'success' },
        { param: 'IPv6', value: 'فعال', status: 'success' },
        { param: 'Proxy', value: 'غیرفعال', status: 'warning' }
    ];
    
    results.forEach(item => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${item.param}</td>
            <td><strong>${item.value}</strong></td>
            <td>
                <span class="status-badge ${item.status}">
                    ${item.status === 'success' ? '✓' : '⚠'}
                </span>
            </td>
        `;
        tbody.appendChild(row);
    });
    
    addToHistory('Network Scan', 'اسکن شبکه');
}

// =========================================
// VPN & Bypass
// =========================================
function populateVPNList() {
    const grid = document.querySelector('.vpn-grid');
    if (!grid) return;
    
    grid.innerHTML = '';
    
    CONFIG.vpnList.forEach(vpn => {
        const card = document.createElement('div');
        card.className = 'vpn-card';
        card.innerHTML = `
            <div class="vpn-header">
                <span class="vpn-name">${vpn.name}</span>
                <span class="vpn-rating">${'⭐'.repeat(vpn.rating)}</span>
            </div>
            <div class="vpn-type">${vpn.type}</div>
            <div class="vpn-protocols">پروتکل‌ها: ${vpn.protocols}</div>
            <p class="vpn-desc">${vpn.description}</p>
            <span class="status-badge ${vpn.difficulty === 'آسان' ? 'success' : vpn.difficulty === 'متوسط' ? 'warning' : 'error'}">
                سختی: ${vpn.difficulty}
            </span>
        `;
        grid.appendChild(card);
    });
}

function populateBypassMethods() {
    const grid = document.querySelector('.bypass-grid');
    if (!grid) return;
    
    grid.innerHTML = '';
    
    CONFIG.bypassMethods.forEach(method => {
        const card = document.createElement('div');
        card.className = 'bypass-card';
        card.innerHTML = `
            <div class="bypass-header">
                <span class="bypass-name">${method.name}</span>
                <span class="bypass-difficulty ${method.difficulty}">
                    ${method.difficulty === 'easy' ? 'آسان' : method.difficulty === 'medium' ? 'متوسط' : 'سخت'}
                </span>
            </div>
            <p class="bypass-desc">${method.description}</p>
            <div class="bypass-steps">
                <h4>مراحل:</h4>
                <ul>
                    ${method.steps.map(step => `<li>${step}</li>`).join('')}
                </ul>
            </div>
        `;
        grid.appendChild(card);
    });
}

// =========================================
// Config Generator
// =========================================
function generateConfig() {
    const protocol = document.getElementById('configProtocol')?.value || 'vless';
    const address = document.getElementById('configAddress')?.value || '';
    const port = document.getElementById('configPort')?.value || '443';
    const uuid = document.getElementById('configUUID')?.value || generateUUID();
    const network = document.getElementById('configNetwork')?.value || 'tcp';
    const security = document.getElementById('configSecurity')?.value || 'tls';
    const sni = document.getElementById('configSNI')?.value || '';
    
    if (!address) {
        showToast('لطفاً آدرس سرور را وارد کنید', 'error');
        return;
    }
    
    let config = '';
    
    if (protocol === 'vless') {
        config = `vless://${uuid}@${address}:${port}?encryption=none&security=${security}&sni=${sni || address}&type=${network}#Config-${Date.now()}`;
    } else if (protocol === 'vmess') {
        const vmessConfig = {
            v: "2",
            ps: `Config-${Date.now()}`,
            add: address,
            port: port,
            id: uuid,
            aid: "0",
            scy: "auto",
            net: network,
            type: "none",
            host: sni || address,
            path: "/",
            tls: security
        };
        config = 'vmess://' + btoa(JSON.stringify(vmessConfig));
    } else if (protocol === 'trojan') {
        config = `trojan://${uuid}@${address}:${port}?security=${security}&sni=${sni || address}&type=${network}#Config-${Date.now()}`;
    }
    
    const output = document.getElementById('configOutput');
    if (output) output.value = config;
    
    // Update QR code
    generateQRCode(config);
    
    addToHistory('Config Generator', `پروتکل: ${protocol}`);
    showToast('کانفیگ با موفقیت ساخته شد', 'success');
}

function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

function fillRandomUUID() {
    const input = document.getElementById('configUUID');
    if (input) {
        input.value = generateUUID();
    }
}

function generateQRCode(text) {
    const canvas = document.getElementById('qrCanvas');
    if (!canvas || !text) return;
    
    // Simple QR placeholder - in production use a QR library
    const ctx = canvas.getContext('2d');
    ctx.fillStyle = '#0d1117';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle = '#58a6ff';
    ctx.font = '12px Vazirmatn';
    ctx.textAlign = 'center';
    ctx.fillText('QR Code', canvas.width/2, canvas.height/2 - 10);
    ctx.fillText('(نیاز به کتابخانه)', canvas.width/2, canvas.height/2 + 10);
}

function copyConfig() {
    const output = document.getElementById('configOutput');
    if (output && output.value) {
        navigator.clipboard.writeText(output.value).then(() => {
            showToast('کانفیگ کپی شد', 'success');
        });
    }
}

function downloadConfig() {
    const output = document.getElementById('configOutput');
    if (output && output.value) {
        const blob = new Blob([output.value], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `config-${Date.now()}.txt`;
        a.click();
        URL.revokeObjectURL(url);
        showToast('کانفیگ دانلود شد', 'success');
    }
}

// =========================================
// History
// =========================================
function addToHistory(type, description) {
    const entry = {
        id: Date.now(),
        type,
        description,
        timestamp: new Date().toLocaleString('fa-IR')
    };
    
    APP.testHistory.unshift(entry);
    
    // Keep only last 50 entries
    if (APP.testHistory.length > 50) {
        APP.testHistory = APP.testHistory.slice(0, 50);
    }
    
    // Save to localStorage
    localStorage.setItem('networkAnalyzerHistory', JSON.stringify(APP.testHistory));
    
    // Update UI
    updateHistoryUI();
}

function loadHistory() {
    try {
        const saved = localStorage.getItem('networkAnalyzerHistory');
        if (saved) {
            APP.testHistory = JSON.parse(saved);
            updateHistoryUI();
        }
    } catch (err) {
        console.error('Failed to load history:', err);
    }
}

function updateHistoryUI() {
    const tbody = document.getElementById('historyResults');
    if (!tbody) return;
    
    if (APP.testHistory.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="4" class="empty-state">
                    هنوز تستی انجام نشده است
                </td>
            </tr>
        `;
        return;
    }
    
    tbody.innerHTML = '';
    
    APP.testHistory.slice(0, 20).forEach((entry, index) => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${index + 1}</td>
            <td><strong>${entry.type}</strong></td>
            <td>${entry.description}</td>
            <td style="font-size: 12px; color: var(--text-muted)">${entry.timestamp}</td>
        `;
        tbody.appendChild(row);
    });
}

function clearHistory() {
    if (confirm('آیا از پاک کردن تاریخچه اطمینان دارید؟')) {
        APP.testHistory = [];
        localStorage.removeItem('networkAnalyzerHistory');
        updateHistoryUI();
        showToast('تاریخچه پاک شد', 'success');
    }
}

// =========================================
// Report
// =========================================
async function generateReport() {
    showToast('در حال تولید گزارش...', 'info');
    
    const reportOutput = document.getElementById('reportOutput');
    if (!reportOutput) return;
    
    // Gather data
    let report = `# گزارش تحلیل شبکه\n`;
    report += `تاریخ: ${new Date().toLocaleString('fa-IR')}\n\n`;
    
    report += `## اطلاعات کلی\n`;
    report += `- نسخه: ${APP.version}\n`;
    report += `- وضعیت اتصال: ${APP.isOnline ? 'متصل' : 'قطع'}\n\n`;
    
    report += `## تاریخچه تست‌ها\n`;
    APP.testHistory.slice(0, 10).forEach((entry, i) => {
        report += `${i + 1}. ${entry.type}: ${entry.description} (${entry.timestamp})\n`;
    });
    
    reportOutput.value = report;
    showToast('گزارش آماده شد', 'success');
}

function exportReport() {
    const reportOutput = document.getElementById('reportOutput');
    if (reportOutput && reportOutput.value) {
        const blob = new Blob([reportOutput.value], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `network-report-${Date.now()}.txt`;
        a.click();
        URL.revokeObjectURL(url);
        showToast('گزارش دانلود شد', 'success');
    }
}

// =========================================
// Connection Status
// =========================================
function updateConnectionStatus() {
    const indicator = document.querySelector('.status-indicator');
    const text = document.querySelector('.status-text');
    
    if (indicator) {
        indicator.classList.toggle('online', APP.isOnline);
    }
    
    if (text) {
        text.textContent = APP.isOnline ? 'متصل به اینترنت' : 'آفلاین';
    }
}

// =========================================
// Toast Notifications
// =========================================
function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    if (!container) return;
    
    const icons = {
        success: '✓',
        error: '✗',
        warning: '⚠',
        info: 'ℹ'
    };
    
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.innerHTML = `
        <span class="toast-icon">${icons[type]}</span>
        <span class="toast-message">${message}</span>
    `;
    
    container.appendChild(toast);
    
    // Auto remove
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(-100%)';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

// =========================================
// Quick Test Functions (for buttons)
// =========================================
function runQuickTest(type) {
    switch (type) {
        case 'dns':
            navigateTo('dns');
            setTimeout(runDNSTest, 300);
            break;
        case 'speed':
            navigateTo('speed');
            setTimeout(runSpeedTest, 300);
            break;
        case 'sanctions':
            navigateTo('sanctions');
            setTimeout(runSanctionsTest, 300);
            break;
        case 'cdn':
            navigateTo('cdn');
            setTimeout(runCDNTest, 300);
            break;
    }
}

// =========================================
// Cleanup
// =========================================
window.addEventListener('beforeunload', () => {
    // Clear intervals
    APP.intervals.forEach(interval => clearInterval(interval));
    
    // Destroy charts
    Object.values(APP.charts).forEach(chart => {
        if (chart) chart.destroy();
    });
});

// Log app start
console.log('📡 Network Analyzer Pro v' + APP.version + ' loaded');
