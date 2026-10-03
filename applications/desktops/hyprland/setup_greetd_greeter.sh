#!/bin/bash

sudo xbps-install -S greetd ReGreet cage accountsservice

sudo mkdir -p /etc/greetd
sudo nano /etc/greetd/config.toml
