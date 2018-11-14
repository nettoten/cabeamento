#!/bin/bash

#Carregue os módulos
modprobe ip_tables

modprobe ip_conntrack

modprobe ip_conntrack_ftp

modprobe iptable_nat

modprobe ip_nat_ftp

modprobe tun

#Limpando políticas padrão definidas
iptables -X
iptables -F
iptables -t nat -X
iptables -t nat -F


#Variáveis de rede
$1=192.168.110.0	#Alterar
$2=192.168.110.126	#Alterar

#Defina as políticas básicas
iptables -t nat -F INPUT
iptables  -F INPUT

##### Definição de Policiamento #####

# Tabela filter

iptables -t filter -P INPUT ACCEPT
iptables -t filter -P OUTPUT ACCEPT
iptables -t filter -P FORWARD ACCEPT

# Tabela nat

iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P OUTPUT ACCEPT
iptables -t nat -P POSTROUTING ACCEPT

##### Proteçaõ contra IP Spoofing #####

for i in /proc/sys/net/ipv4/conf/*/rp_filter; do

echo 1 >$i

done

##### Ativamos o redirecionamento de pacotes (requerido para NAT) #####

echo "1" >/proc/sys/net/ipv4/ip_forward

#echo "2048" > /proc/sys/net/ipv4/ip_conntrack_max



###############################################################

					# Tabela filter #

###############################################################

##### Chain INPUT #####

# Aceita todo o trafego vindo do loopback e indo pro loopback

iptables -A INPUT -i lo -j ACCEPT

# Todo trafego vindo da rede interna e das Filiais tambem sao aceitos

iptables -A INPUT -s $1 -i enp0s8 -j ACCEPT	#Pode comentar a variável e substituir diretamente pelo IP

iptables -A INPUT -s $2 -i enp0s8 -j ACCEPT

# Liberacao de PING (ICMP) na Interface Externa com certa limitacao
iptables -A INPUT -i enp0s8 -p icmp -m limit --limit 2/s -j ACCEPT

#Liberacao de portas de servico para interface externa
# Porta 22 SSH
iptables -A INPUT -i enp0s8 -p tcp --sport 22 -j ACCEPT
# Porta Proxy
iptables -A INPUT -i enp0s8 -p tcp --sport 3128 -j ACCEPT
# Porta Zabbix
iptables -A INPUT -i enp0s8 -p tcp --sport 10050 -j ACCEPT

# Masquerade (NAT)
iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE

#Roteamento por dentro da VPN
ip route add 192.168.110.0/24 dev tun0 #Alterar
