#!/bin/bash

# Prepare directory hosting a certificate and a key
sudo mkdir /etc/apache2/ssl

# Create a certificate and a key
echo "Generating key and certificate..."
sudo openssl req -x509 -nodes -days 3650 -subj "/C=EU/ST=Someland/L=Some City/O=Sample/CN=10.2.3.89" -newkey rsa:2048 -keyout /etc/apache2/ssl/repo.key -out /etc/apache2/ssl/repo.crt
echo ""

echo "Done."
