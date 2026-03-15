# Fail2banJail-Analyzer
This project is a lightweight bash tool which can be used to preliminary analyze banned IPs'characteristics.  
This script is designed for **Ubuntu** operating systems and had been tested on **Ubuntu 22.04**.  
It haven't been tested on other **Linux-Based** operating systems so maybe the script doesn't suit for them.   

The script use database to analyze IPs'**Country** and **Cities** else **ASN Owner**.   
Limited by database,it can only provide those informations.  

It can preliminary analyze those IP which is banned by Fail2ban.It's output will show the basic characteristics of IPs.  
The IPs from the jails of Fail2ban and the databases from [MaxMind's GeoLite2](https://dev.maxmind.com/geoip/geoip2/geolite2/).  
The script quote **[P3TERX](https://github.com/P3TERX/)**'s project--**[GeoLite.mmdb](https://github.com/P3TERX/GeoLite.mmdb)** as its database updating source  
