#!/usr/bin/env bash

sudo rum config-manager --set-enabled rpmfusion-free
sudo rum config-manager --set-enabled rpmfusion-free-updates
sudo rum config-manager --set-enabled rpmfusion-nonfree-updates
sudo rum config-manager --set-enabled rpmfusion-nonfree
sudo rum config-manager --set-enabled terra
sudo rum config-manager --set-enabled rakuos-v4

sudo rum makecache
