<h1>🛡️ Azure Honeypot with Sentinel Watchlist-Based Geolocation</h1>

<h2>📌 Project Overview</h2>
<p>
  This project is a virtual honeypot deployed in <a href="https://azure.microsoft.com/" target="_blank">Microsoft Azure</a>, designed to detect and visualize unauthorized login attempts in real time. The honeypot runs on a Windows virtual machine and captures failed RDP login attempts using Windows Event Viewer (Event ID 4625).

  A Data Collection Rule (DCR) in <a href="https://learn.microsoft.com/azure/sentinel/" target="_blank">Microsoft Sentinel</a> is used to automatically pull security logs from the virtual machine into a Log Analytics Workspace. To enrich the data with geolocation, a custom spreadsheet containing IP address mappings to country, city, latitude, and longitude is uploaded into Sentinel as a Watchlist.
  
  Using <a href="https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/" target="_blank">Kusto Query Language (KQL)</a>, the failed login attempts are joined with the watchlist data, enabling geographic insights. These are visualized in a Sentinel Workbook through an interactive map displaying real-time attack origins. This project demonstrates the use of native Azure tools for cloud security, log collection, and threat visualization.
</p>

<h2>🛠️ Technologies Used</h2>
<ul>
  <li><strong>Microsoft Azure</strong> – Cloud platform for infrastructure deployment</li>
  <li><strong>Windows 10 Pro</strong> – VM operating system simulating a vulnerable system</li>
  <li><strong>Windows Event Viewer</strong> – Detects failed RDP login attempts (Event ID 4625)</li>
  <li><strong>Microsoft Sentinel</strong> – Cloud-native SIEM for log ingestion and analysis</li>
  <li><strong>Data Collection Rule (DCR)</strong> – Automates the pulling of logs from VM to Log Analytics</li>
  <li><strong>Azure Log Analytics Workspace</strong> – Central repository for logs and queries</li>
  <li><strong>Sentinel Watchlist</strong> – Uploaded spreadsheet used for geolocation lookups</li>
  <li><strong>Kusto Query Language (KQL)</strong> – Used to join logs and watchlist data</li>
  <li><strong>Microsoft Sentinel Workbook</strong> – Visualizes geolocation data on a real-time map</li>
</ul>

<h2>⚙️ Deployment Notes</h2>
<p><strong>Note:</strong> This project is hosted in a personal Microsoft Azure environment and is not designed to be run locally. However, it can be replicated using the instructions and PowerShell script provided.</p>

<ol>
  <li>
    <p>Deploy a Windows VM in Azure and enable RDP access.</p>
    <img src="https://i.imgur.com/h0jNQH2.png" alt="Step 1 - Deploy VM" style="max-width: 100%; border-radius: 8px;">
  </li>
  <li>
    <p>Modify VM’s Network Security Group to allow public RDP and disable the firewall inside the VM.</p>
    <img src="https://i.imgur.com/tPrI1TS.png" alt="NSG Config" style="max-width: 100%; border-radius: 8px;">
    <img src="https://i.imgur.com/euKjO2A.png" alt="Firewall Disabled" style="max-width: 100%; border-radius: 8px;">
  </li>
  <li>
    <p>Ensure Event ID 4625 (failed login attempts) is being logged.</p>
    <img src="https://i.imgur.com/01D98Yh.png" alt="Event ID Logging" style="max-width: 100%; border-radius: 8px;">
  </li>
  <li>
    <p>Create a Log Analytics Workspace (LAW) and a Microsoft Sentinel Instance.</p>
    <img src="https://i.imgur.com/U5VxRBA.png" alt="LAW" style="max-width: 100%; border-radius: 8px;">
    <img src="https://i.imgur.com/b3fmeku.png" alt="Sentinel Instance" style="max-width: 100%; border-radius: 8px;">
  </li>
  <li>
    <p>Create a Data Collection Rule (DCR) to forward logs to Log Analytics.</p>
    <img src="https://i.imgur.com/GMUzbE4.png" alt="DCR" style="max-width: 100%; border-radius: 8px;">
    <img src="https://i.imgur.com/d77kHkm.png" alt="DCR Setup" style="max-width: 100%; border-radius: 8px;">
  </li>
  <li>
    <p>Prepare and upload a spreadsheet with IP address and geolocation data (city, country, lat/long) to Sentinel Watchlists.</p>
    <img src="https://i.imgur.com/nwug2jZ.png" alt="Watchlist Upload" style="max-width: 100%; border-radius: 8px;">
    <img src="https://i.imgur.com/ynzZUld.png" alt="Watchlist Preview" style="max-width: 100%; border-radius: 8px;">
  </li>
  <li>
    <p>Create a Workbook and use KQL to join login data with watchlist records.</p>
    <pre><code>let GeoIPDB_FULL = _GetWatchlist("geoip");
let WindowsEvents = SecurityEvent;
WindowsEvents | where EventID == 4625
| order by TimeGenerated desc
| evaluate ipv4_lookup(GeoIPDB_FULL, IpAddress, network)
| summarize FailureCount = count() by IpAddress, latitude, longitude, cityname, countryname
| project FailureCount, AttackerIp = IpAddress, latitude, longitude, city = cityname, country = countryname,
friendly_location = strcat(cityname, " (", countryname, ")");</code></pre>
    <img src="https://i.imgur.com/s4N2uyc.png" alt="KQL Workbook" style="max-width: 100%; border-radius: 8px;">
  </li>
</ol>

<p><strong>Attacks map after 16 hours:</strong></p>
<img src="https://i.imgur.com/A6kqSUZ.png" alt="Attack Map" style="max-width: 100%; border-radius: 8px;">

<h2>🚀 Future Improvements</h2>
<ul>
  <li>Enable alerts and automated playbooks to respond to brute-force activity</li>
  <li>Expand the watchlist with additional intelligence sources or IP reputation data</li>
  <li>Add honeypots with other protocols (e.g., SSH, FTP) to diversify threat monitoring</li>
  <li>Integrate with Power BI or a web dashboard for advanced analytics</li>
  <li>Experiment with anomaly detection using Azure ML or built-in Sentinel rules</li>
</ul>

<h2>🙏 Credits</h2>
<p><a href="https://github.com/joshmadakor1/joshmadakor1" target="_blank"><strong>Josh Madakor</strong></a> – Special thanks for the original concept and guidance on building Azure-based cybersecurity labs. His tutorials inspired the structure of this project.</p>

<p style="text-align: center; font-size: 14px; color: gray;">
  © 2025 Emmanuel Encarnacion • GitHub Portfolio
</p>
