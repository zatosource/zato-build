#!/bin/bash

if [[ -z "$1" ]]; then
    HOWMANYSERVERS=2
elif [ "$1" -le 10 ]; then
    HOWMANYSERVERS=$1
else
    echo "Please change number of servers. Servers range 1..10"
    exit
fi

#create CA
echo "Generating CA..."
openssl genrsa -out zato.ca.key.pem 2048
openssl req -new -x509 -days 3650 -extensions v3_ca -subj "/C=EU/ST=Zatoland/L=Zato City/O=Zato/CN=Zato Dev CA" -key zato.ca.key.pem -out ca_cert.pem
echo ""

#create load balancer certs
echo "Generating Load Balancer certs..."
openssl genrsa -out zato.load_balancer.key.pem 2048
openssl rsa -in zato.load_balancer.key.pem -pubout -out zato.load_balancer.key.pub.pem
openssl req -new -key zato.load_balancer.key.pem -out zato.load_balancer.req.csr -subj "/C=EU/ST=Zatoland/L=Zato City/O=Zato/CN=Zato Dev Load Balancer"
openssl x509 -req -days 365 -in zato.load_balancer.req.csr -CA ca_cert.pem -CAkey zato.ca.key.pem -CAcreateserial -out zato.load_balancer.cert.pem
rm -f zato.load_balancer.req.csr
echo ""

#create web admin certs
echo "Generating Web Admin certs..."
openssl genrsa -out zato.web_admin.key.pem 2048
openssl rsa -in zato.web_admin.key.pem -pubout -out zato.web_admin.key.pub.pem
openssl req -new -key zato.web_admin.key.pem -out zato.web_admin.req.csr -subj "/C=EU/ST=Zatoland/L=Zato City/O=Zato/CN=Zato Dev Web Admin"
openssl x509 -req -days 365 -in zato.web_admin.req.csr -CA ca_cert.pem -CAkey zato.ca.key.pem -CAcreateserial -out zato.web_admin.cert.pem
rm -f zato.web_admin.req.csr
echo ""

#create servers certs
i=1
while [ $i -le $HOWMANYSERVERS ]
do
echo "Generating Server $i certs..."
openssl genrsa -out zato.server$i.key.pem 2048
openssl rsa -in zato.server$i.key.pem -pubout -out zato.server$i.key.pub.pem
openssl req -new -key zato.server$i.key.pem -out zato.server$i.req.csr -subj "/C=EU/ST=Zatoland/L=Zato City/O=Zato/CN=Zato Dev Server $i"
openssl x509 -req -days 365 -in zato.server$i.req.csr -CA ca_cert.pem -CAkey zato.ca.key.pem -CAcreateserial -out zato.server$i.cert.pem
rm -f zato.server$i.req.csr
echo ""
i=$[i+1]
done

rm -f ca_cert.srl

echo "Done."