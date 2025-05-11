# 🛡️ Azure Honeypot with Geolocation & Sentinel Integration

## 📌 Project Overview
This project is a virtual honeypot deployed in [Microsoft Azure](https://azure.microsoft.com/), designed to detect and visualize unauthorized login attempts in real time. The honeypot runs on a Windows virtual machine and captures failed RDP login attempts using Windows Event Viewer (Event ID 4625).  

A Data Collection Rule (DCR) in [Microsoft Sentinel](https://learn.microsoft.com/azure/sentinel/) is used to automatically pull security logs from the virtual machine into a Log Analytics Workspace. To enrich the data with geolocation, a custom spreadsheet containing IP address mappings to country, city, latitude, and longitude is uploaded into Sentinel as a Watchlist.  

Using [Kusto Query Language (KQL)](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/), the failed login attempts are joined with the watchlist data, enabling geographic insights. These are visualized in a Sentinel Workbook through an interactive map displaying real-time attack origins.  
This project demonstrates the use of native Azure tools for cloud security, log collection, and threat visualization.

## 🛠️ Technologies Used
- **Microsoft Azure** – Cloud platform for infrastructure deployment  
- **Windows 10 Pro** – VM operating system simulating a vulnerable system  
- **Windows Event Viewer** – Detects failed RDP login attempts (Event ID 4625)  
- **Microsoft Sentinel** – Cloud-native SIEM for log ingestion and analysis  
- **Data Collection Rule (DCR)** – Automates the pulling of logs from VM to Log Analytics  
- **Azure Log Analytics Workspace** – Central repository for logs and queries  
- **Sentinel Watchlist** – Uploaded spreadsheet used for geolocation lookups  
- **Kusto Query Language (KQL)** – Used to join logs and watchlist data  
- **Microsoft Sentinel Workbook** – Visualizes geolocation data on a real-time map  

## ⚙️ Deployment Notes
**Note:** This project is hosted in a personal Microsoft Azure environment and is not designed to be run locally. However, it can be replicated using the instructions and PowerShell script provided.

### To Replicate This Project:
1. **Deploy a Windows VM in Azure and enable RDP access**  
   ![Step 1](https://i.imgur.com/h0jNQH2.png)

2. **Modify VM’s Network Security Group to allow public RDP and disable the firewall inside the VM**  
   ![NSG Config](https://i.imgur.com/tPrI1TS.png)  
   ![Firewall Disabled](https://i.imgur.com/euKjO2A.png)

3. **Ensure Event ID 4625 (failed login attempts) is being logged**  
   ![Event ID Logging](https://i.imgur.com/01D98Yh.png)

4. **Create a Log Analytics Workspace (LAW) and a Microsoft Sentinel Instance**  
   ![LAW](https://i.imgur.com/U5VxRBA.png)  
   ![Sentinel Instance](https://i.imgur.com/b3fmeku.png)

5. **Create a Data Collection Rule (DCR) to forward logs to Log Analytics**  
   ![DCR](https://i.imgur.com/GMUzbE4.png)  
   ![DCR Setup](https://i.imgur.com/d77kHkm.png)

6. **Prepare and upload a spreadsheet with IP address and geolocation data (city, country, lat/long) to Sentinel Watchlists**  
   ![Watchlist Upload](https://i.imgur.com/nwug2jZ.png)  
   ![Watchlist Preview](https://i.imgur.com/ynzZUld.png)

7. **Create a Workbook and use KQL to join login data with watchlist records**
```kql
let GeoIPDB_FULL = _GetWatchlist("geoip");
let WindowsEvents = SecurityEvent;
WindowsEvents | where EventID == 4625
| order by TimeGenerated desc
| evaluate ipv4_lookup(GeoIPDB_FULL, IpAddress, network)
| summarize FailureCount = count() by IpAddress, latitude, longitude, cityname, countryname
| project FailureCount, AttackerIp = IpAddress, latitude, longitude, city = cityname, country = countryname,
friendly_location = strcat(cityname, " (", countryname, ")");
```
   ![KQL Workbook](https://i.imgur.com/s4N2uyc.png)

**Attacks map after 16 hours:**  
![Attack Map](https://i.imgur.com/A6kqSUZ.png)

## 🚀 Future Improvements
- Enable alerts and automated playbooks to respond to brute-force activity  
- Expand the watchlist with additional intelligence sources or IP reputation data  
- Add honeypots with other protocols (e.g., SSH, FTP) to diversify threat monitoring  
- Integrate with Power BI or a web dashboard for advanced analytics  
- Experiment with anomaly detection using Azure ML or built-in Sentinel rules  

## 🙏 Credits
[**Josh Madakor**](https://github.com/joshmadakor1/joshmadakor1) – Special thanks for the original concept and guidance on building Azure-based cybersecurity labs. His tutorials inspired the structure of this project.

---
© 2025 Emmanuel Encarnacion • GitHub Portfolio
