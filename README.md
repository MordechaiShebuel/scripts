# scripts

Collection of shell scripts for updating a system, and initializing a system with the apps you use. I tried to keep the update, restore system scripts system agnostic for three distros that are anti-woke and have taken a stronger approach against the communist Age Verification bills. I am using AI from Grok to assist in this repo, as we are running out of time to deploy and own our hardware and software. It is crucial we get routers that are not owned by the deep state, and access to media that we can control. 

Every script is still in process of development and testing.

## flatpak_conversion.sh
- Created this after it was revealed that the Flathub team was working on implementing Age Verification
- There are some issues with the profiles in Firefox based browsers, but you can switch to the correct profile by typing `about:profiles` in the address bar, and making the correct profile the default.
- Make sure you back up anything you don't want deleted!
- This script is *NOT* system agnostic and will only work on Artix

## create_nomad_vendewolf.sh
https://github.com/Crosstalk-Solutions/project-nomad?tab=readme-ov-file
- Creates a podman instance of Project NOMAD
    - Checks to see if podman is already installed and if not installs it.
    - Vibe coded with Grok
    - commands:
    ```
    chmod +x create-nomad-openrc.sh
    sudo ./create-nomad-openrc.sh
    ```
    
## create_router_vendewolf.sh
- Turns your Vendewolf machine into a router. This can be used with your ISP's router, just connect one of the Ethernet ports to your device.
    - Script assumes your ISP router's WAN is `192.168.1.1` if your is different you will need to change it.
    - You may also need to adjust the `ethx` values in the script before running it. (instructions are in the script)
    - Vibe coded with Grok
