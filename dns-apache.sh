#!/bin/bash

rm /etc/apt/sources.list
echo "deb http://deb.debian.org/debian/ bullseye main
deb-src http://deb.debian.org/debian/ bullseye main
deb http://security.debian.org/debian-security bullseye-security main contrib
deb-src http://security.debian.org/debian-security bullseye-security main contrib
deb http://deb.debian.org/debian/ bullseye-updates main contrib
deb-src http://deb.debian.org/debian/ bullseye-updates main contrib"  | tee -a /etc/apt/sources.list > /dev/null

apt update && apt upgrade -y
apt install bind9 dnsutils -y

IP=$(hostname -I)
read A B C D <<<"${IP//./ }"
msg1='$'
TTL="${msg1}TTL"
ktip='"'

echo "Konfigurasi DNS $1"
echo "Dengan IP = $IP"

echo ";
; BIND data file for local loopback interface
;
$TTL    604800
@       IN      SOA     $1. root.$1. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      $1.
@       IN      A       $IP
www     IN      A       $IP
subdomain    IN      CNAME   www" | tee -a /etc/bind/db.domain > /dev/null

echo ";
; BIND reverse data file for local loopback interface
;
$TTL    604800
@       IN      SOA     $1. root.$1. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      $1.
$D      IN      PTR     $1." | tee -a /etc/bind/db.rev > /dev/null

echo "zone $ktip$1$ktip{
        type master;
        file $ktip/etc/bind/db.domain$ktip;
};

zone $ktip$C.$B.$A.in-addr.arpa$ktip{
        type master;
        file $ktip/etc/bind/db.rev$ktip;
};" | tee -a /etc/bind/named.conf.local > /dev/null

rm /etc/bind/named.conf.options
echo "options {
        directory $ktip/var/cache/bind$ktip;
        forwarders {
                8.8.8.8;
        };
        dnssec-validation no;

        listen-on-v6 { any; };
};" | tee -a /etc/bind/named.conf.options > /dev/null

echo "nameserver $IP" | tee -a /etc/resolv.conf > /dev/null

systemctl restart bind9

echo "Sukses !"
