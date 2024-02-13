#!/bin/bash
echo -n > /etc/servers_hosts
echo -n > /etc/bad_servers
echo -n > /etc/reservehosts
echo -n > /etc/anotherhosts
hosts=("1.1.1.2" "1.1.1.3" "1.1.1.4")
for h in ${hosts[@]}; do
  result=$(curl -Is http://$h --connect-timeout 2 | head -n 1 )
  pattern="HTTP/1.1 200 OK";
  if [[ $result =~ $pattern ]]; then
    echo $h >> /etc/servers_hosts
    echo $h
    echo "host 1" | curl --data-binary @- http://your_prometheus.server:9091/metrics/job/servers/instance/$h --connect-timeout 2
  else
    echo "$h is down" >> /etc/bad_servers
    echo "$h is down"
    echo "host 0" | curl --data-binary @- http://your_prometheus.server:9091/metrics/job/servers/instance/$h --connect-timeout 2
  fi
done
echo "________reserve_________"
reservehosts=("1.1.1.5" "1.1.1.6" "1.1.1.7")
for i in ${reservehosts[@]}; do
  result=$(curl -Is http://$i --connect-timeout 2 | head -n 1 )
  pattern="HTTP/1.1 200 OK";
  if [[ $result =~ $pattern ]]; then
    echo $i >> /etc/reservehosts
    echo $i
    echo "reserve 1" | curl --data-binary @- http://your_prometheus.server:9091/metrics/job/reserve/instance/$i --connect-timeout 2
  else
    echo "$i is down" >> /etc/bad_servers
    echo "$i is down"
    echo "reserve 0" | curl --data-binary @- http://your_prometheus.server:9091/metrics/job/reserve/instance/$i --connect-timeout 2
  fi
done
echo "DNS 1" | curl --data-binary @- http://your_prometheus.server:9091/metrics/job/dns/instance/31.192.106.11 --connect-timeout 2
#Check
echo "________Checking_________"
 if [ -s /etc/servers_hosts ]
 then
 echo "Servers exist"
 else
 echo "Hosts offline"
 mv /etc/reservehosts /etc/servers_hosts
 fi

echo "________another_method_________"
anotherhosts=("1.1.12.6" "1.8.1.2")
for k in ${anotherhosts[@]}; do
  result=$(curl -Is http://$k --connect-timeout 2 | head -n 1 )
  pattern="HTTP/1.1 200 OK";
  pattern2="HTTP/1.1 301 Moved Permanently";
  if [[ $result =~ $pattern2 ]]; then
    echo $k >> /etc/anotherhosts
    echo $k
    echo "anotherhosts 1" | curl --data-binary @- http://your_prometheus.server:9091/metrics/job/balancer/instance/$k --connect-timeout 2
  else
    echo "$k is down" >> /etc/bad_servers
    echo "$k is down"
    echo "anotherhosts 0" | curl --data-binary @- http://your_prometheus.server:9091/metrics/job/balancer/instance/$k --connect-timeout 2
  fi
done
#First method
#One IP for all domains
NewIpForanotherhosts=$(shuf -n 1  /etc/anotherhosts)
sed -i "/^address=/s/[^=]*$/\x2F\x23\x2F${NewIpForanotherhosts}/" /etc/dnsmasq.conf
#Second method
#Manual records for everyone your domains
shuf -n 2  /etc/servers_hosts |  awk '$0=$0" yourdomain.com"' > /etc/banner_add_hosts
shuf -n 1  /etc/reservehosts |  awk '$0=$0" yourdomain2.com"' >> /etc/banner_add_hosts
shuf -n 1  /etc/servers_hosts |  awk '$0=$0" yourdomain3.com www.yourdomain3.com"' >> /etc/banner_add_hosts
#Another one method
#Automated
echo -n > /etc/caa.conf
# /etc/domains.conf  - list of all your domains
for domains in $(cat /etc/domains.conf); do
 shuf -n 1  /etc/servers_hosts |  echo $(awk '$0=$0') $domains www.$domains >> /etc/banner_add_hosts
 echo dns-rr=$domains,257,000569737375656C657473656E63727970742E6F7267 >> /etc/caa.conf
 echo dns-rr=www.$domains,257,000569737375656C657473656E63727970742E6F7267 >> /etc/caa.conf
 done
 #Add CAA-records for first method domains
for anotherhosts_domains in $(cat /etc/anotherhosts_domains.conf); do
 echo dns-rr=$anotherhosts_domains,257,000569737375656C657473656E63727970742E6F7267 >> /etc/caa.conf
 done
#reboot
dnspid="$(pgrep dnsmasq)" && kill -1 $dnspid
service dnsmasq restart
