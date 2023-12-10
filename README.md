# Install Zabbix automatically

Welcome to my Github repository dedicated to automating the installation of Zabbix, an essential network monitoring and management solution. Here you'll find a set of scripts and resources designed to simplify and speed up the process of installing Zabbix on various platforms (mainly Linux). Whether you're a system administrator, security manager or network monitoring enthusiast, this repository aims to make Zabbix configuration easier, saving you time and effort.

Automating Zabbix installation is crucial to ensuring consistent configuration, avoiding human error and simplifying the deployment of monitoring solutions. The scripts provided here are designed to run seamlessly on different Linux distributions and other operating systems, allowing you to concentrate on effectively monitoring your networks and systems.

Feel free to explore the scripts and guides provided in this repository to get started quickly with Zabbix and take advantage of its benefits for proactive monitoring of your infrastructure. If you have any questions or suggestions, please don't hesitate to share them. We value your input and expertise.

Ready to simplify your Zabbix installation process ? Let's dive into the world of automation !

## Install

Clone repository Install_auto_Zabbix on your host:
```bash
git clone https://github.com/NANDILLONMaxence/Install_auto_Zabbix.git
chmod +x Install_auto_Zabbix/*.sh
cd Install_auto_Zabbix
```
launch the script
```bash
./001_Zabbix_debian-11.bash
```
---
## Web interface configuration

After running the installation script :

<img src= "https://github.com/NANDILLONMaxence/Install_auto_Zabbix/blob/main/screens/zabbix.png" width="100%" />


Open your web browser and enter the IP and port of your Zabbix server :

<img src= "https://github.com/NANDILLONMaxence/Install_auto_Zabbix/blob/main/screens/out.png"  width="40%" />


On the first page, choose your default language :

<img src= "https://github.com/NANDILLONMaxence/Install_auto_Zabbix/blob/main/screens/zabbix_main.png" width="100%" />

To configure the database connection :
- Uncheck `TLS encryption`
- Enter `the password` you have set for the zabbix database

<img src= "https://github.com/NANDILLONMaxence/Install_auto_Zabbix/blob/main/screens/zabbix_second.png" width="100%" />

In the next window, select :
- The `server name` Zabbix
- Your `Timezone` setting
- Your `theme`
  
<img src= "https://github.com/NANDILLONMaxence/Install_auto_Zabbix/blob/main/screens/zabbix_name.png" width="100%" />

For the first connection, you will need to enter the default name and password:
- User name `Admin`
- password `zabbix`

<img src= "https://github.com/NANDILLONMaxence/Install_auto_Zabbix/blob/main/screens/Connexion_default.png" width="40%" />

Your Zabbix environment is ready to use :

<img src= "https://github.com/NANDILLONMaxence/Install_auto_Zabbix/blob/main/screens/monitor.png" width="100%" />
