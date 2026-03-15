# Fail2banJail-Analyzer
* **Introduction**  
This project is a lightweight bash tool which can be used to preliminary analyze banned IPs'characteristics.  
This script is designed for **Ubuntu** operating systems and had been tested on **Ubuntu 22.04**.  
It haven't been tested on other **Linux-Based** operating systems so maybe the script doesn't suit for them.   

* **Function**  
The script use database to analyze IPs'**Country** and **Cities** else **ASN Owner**.   
Limited by database,it can only provide those informations.  
It can preliminary analyze those IP which is banned by Fail2ban.It's output will show the basic characteristics of IPs.  
The IPs come from the jails of Fail2ban.

* **License**  
The databases from **[MaxMind's GeoLite2](https://dev.maxmind.com/geoip/geoip2/geolite2/)**.  
The script quote **[P3TERX](https://github.com/P3TERX/)**'s project--**[GeoLite.mmdb](https://github.com/P3TERX/GeoLite.mmdb)** as its database updating source.  
Spacial thanks to **[P3TERX](https://github.com/P3TERX/)**.  
[Creative Commons Corporation Attribution-ShareAlike 4.0 International License (the "Creative Commons License")](https://creativecommons.org/licenses/by-sa/4.0/)
