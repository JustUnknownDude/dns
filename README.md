<b> In the process of filling... </b>
Later I will add an auto-deployment script

# An example process of how to set up load balancing at the DNS server level

Will use Centos and Dnsmasq as DNS server

### 1. First you need to install dnsmasq

```bash
yum install dnsmasq bind-utils
```


--------<b> I don't remember if this is necessary</b> ----------<br>
~~Next, specify 127.0.0.1 as the DNS server~~
   ```bash
   echo “nameserver 127.0.0.1” > /etc/resolv.conf
 ```
--------------------------!--------------------------------------

### 2.Next, copy the following files to /etc/ : 
- dnsmasq.conf
- domains.conf
- servertest.sh

  In the dnsmasq.conf file you need to add your server IP:
  listen-address=YOUR_IP

  domains.conf - list of your domains, if there is more than one

  servertest.sh - here you need to specify the IP of your servers

  ### 3. Add servertest.sh to Cron

  ```bash
  crontab -e
  ```

  ```
  */2 * * * * bash /etc/serverstest.sh > /dev/null 2>&1
  ```
