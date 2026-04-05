# scripts

Collection of shell scripts for updating a system, and initializing a system with the apps you use. I tried to keep the update, restore system scripts system agnostic for three distros that are anti-woke and have taken a stronger approach against the communist Age Verification bills. I am using AI from Grok to assist in this repo, as we are running out of time to deploy and own our hardware and software. It is crucial we get routers that are not owned by the deep state, and access to media that we can control. 

Every script is still in process of development and testing.

The readme is organized in the matter you should run them. You'll want to setup the router first, and then the other services.

## create_router_vendewolf.sh
- Turns your Vendewolf machine into a router. This can be used with your ISP's router, just connect one of the Ethernet ports to your device.
    - Script assumes your ISP router's WAN is `192.168.1.1` if your is different you will need to change it.
    - You may also need to adjust the `ethx` values in the script before running it. (instructions are in the script)
    - Vibe coded with Grok
    - Testing revealed that the Program kept trying to install docker, I'm trying to stick to a more secure libre stack, podman, Xlibre, OpenRC. I created a Python patch program that just simply removed the call to install docker.
    - Latest version is failing to verify the CURLd IMG file. The SHA doesn't match expected. This could be a Vibe issue, need to dig into it.
- current version gets interface up, but requires manual intervention via the console to properly wire the ethernet connectors. Also had to manually disable NetworkManager, to keep eth0 from getting an IP assigned. 
- Tried connecting external computer to WAN port, and it's getting leaked data from 192.168.1.1 DHCP. Need to try and release and renew on client machine.
1. unplug the client
2. run `sudo dhclient -r && sudo dhclient`
3. plug interface back in

- If that doesn't work need to verify host routing
1. script enables `net.ipv4.ip_forward=1` which it needs inside the VM, however host could be trying to route packets to client because of this. to test if this is the issue (only if prior fails to resolve)
    run `sudo sysctl -w net.ipv4.ip_forward=0`
    - If this does resolve the issue, will need to query how to make sure I am still forwarding traffic to the VM without forwarding it to the client.
- If the above didn't resolve, verify LAN(vtnet1) in interface says 10.0.0.1 (it does)
    - select option 8 (shell) type `pluginctl -s dhcpd status` should report, `program is running`
        - this seems to be the issue, need to dig in here.
- Run `sudo brctl show` are `eth0` and `enx..` in completely different bridge groups?
- Resolution:
    - Make sure gateway is setup to point to 192.168.1.1 (Modem / IP Router)
        - Make sure it is default, priority 1
    - Disable IPV6 under WAN settings
    - power off everything, including IP Modem/Router
    - Connect cables to devices to use new LAN
    - Power on, devices are on new subnet, through OPNSense router
    
## update_dns_blocking_opnsense.sh
- Created to replace create_piihole_vendewolf.sh
- downloads list of tracking / poison dns services and blocks them at the router level. 
- This isn't even really necessary, OPNSense FW includes large list of DNS level tracking and ad blockers you can just select and enable.

## create_jellyfin_vendewolf.sh
- This is a media server, that is free and does not share your metadata with third parties.
    - Have not tested yet

## create_plex_vendewolf.sh
- Abandoned script, decided to try Jellyfin instead of this service.
    - Plex sends metadata from your server to their customers
    - Plex charges money for certain features.

## create_piihole_vendewolf.sh
- This should be ran immediately after installing OPNSense virtual router. 
    - Setups up a bridge to the router IP address (10.0.0.1) to make a PIIHOLE server at 10.0.0.2
- I'm discontinuing development on this, Grok was leading me down a rabbit trail that is unnecessary for OPNSense. 
    
## create_nomad_vendewolf.sh
https://github.com/Crosstalk-Solutions/project-nomad?tab=readme-ov-file
- Creates a podman instance of Project NOMAD
    - Checks to see if podman is already installed and if not installs it.
    - Setup to use 10.0.0.3 bridge on port 8080
    - Vibe coded with Grok
    - commands:
    ```
    chmod +x create-nomad-openrc.sh
    sudo ./create-nomad-openrc.sh
    ```
- Set aside work on this to get the OPNSense router up first.
    
## flatpak_conversion.sh
- Created this after it was revealed that the Flathub team was working on implementing Age Verification
- There are some issues with the profiles in Firefox based browsers, but you can switch to the correct profile by typing `about:profiles` in the address bar, and making the correct profile the default.
- Make sure you back up anything you don't want deleted!
- This script is *NOT* system agnostic and will only work on Artix
