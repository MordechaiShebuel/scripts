#!/bin/bash

# HDCP Compliance Stack Report
# Checks: Kernel -> GPU Driver -> HDMI -> Monitor EDID

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

COMPLIANT=true

# Helper function to check if device is HDCP compliant
check_hdcp_compliance() {
    local device="$1"
    local status="$2"

    if [[ "$status" =~ "disabled" || "$status" =~ "not" || "$status" == "0" ]]; then
        echo -e "${RED}✗ $device: NOT HDCP COMPLIANT${NC}"
        COMPLIANT=false
    elif [[ "$status" =~ "enabled" || "$status" =~ "supported" || "$status" == "1" ]]; then
        echo -e "${GREEN}✓ $device: HDCP Compliant${NC}"
    else
        echo -e "${YELLOW}? $device: HDCP Status Unknown${NC}"
    fi
}

# 1. Check Kernel HDCP Support
echo "=== KERNEL HDCP SUPPORT ==="
if grep -q "CONFIG_DRM_HDCP=y" /boot/config-$(uname -r) 2>/dev/null; then
    check_hdcp_compliance "Kernel DRM HDCP" "enabled"
else
    check_hdcp_compliance "Kernel DRM HDCP" "disabled"
fi

# 2. Check GPU Driver (Intel, AMD, NVIDIA)
echo -e "\n=== GPU DRIVER HDCP SUPPORT ==="

# Intel GPU (i915 driver)
if modinfo i915 &>/dev/null; then
    intel_hdcp=$(cat /sys/module/i915/parameters/enable_hdcp 2>/dev/null || echo "-1")
    if [[ "$intel_hdcp" == "1" || "$intel_hdcp" == "Y" ]]; then
        check_hdcp_compliance "Intel GPU (i915)" "enabled"
    elif [[ "$intel_hdcp" == "0" || "$intel_hdcp" == "N" ]]; then
        check_hdcp_compliance "Intel GPU (i915)" "disabled"
    fi
fi

# AMD GPU (amdgpu driver)
if modinfo amdgpu &>/dev/null; then
    amd_hdcp=$(cat /sys/module/amdgpu/parameters/hdcp_support 2>/dev/null || echo "-1")
    if [[ "$amd_hdcp" == "1" ]]; then
        check_hdcp_compliance "AMD GPU (amdgpu)" "enabled"
    elif [[ "$amd_hdcp" == "0" ]]; then
        check_hdcp_compliance "AMD GPU (amdgpu)" "disabled"
    fi
fi

# NVIDIA GPU (Check via nvidia-smi if available)
if command -v nvidia-smi &>/dev/null; then
    nvidia_hdcp=$(nvidia-smi --query=gpu.name --format=csv,noheader 2>/dev/null && echo "present")
    if [[ -n "$nvidia_hdcp" ]]; then
        # NVIDIA proprietary driver - check /proc/driver/nvidia/gpus/*/information
        nvidia_hdcp_status=$(cat /proc/driver/nvidia/gpus/*/information 2>/dev/null | grep -i hdcp || echo "")
        if [[ -z "$nvidia_hdcp_status" ]]; then
            check_hdcp_compliance "NVIDIA GPU" "supported"
        fi
    fi
fi

# 3. Check HDMI Connections and HDCP
echo -e "\n=== HDMI/HDCP CONNECTOR STATUS ==="

# Use drm_info or xrandr to find HDMI connectors
if command -v drm_info &>/dev/null; then
    hdmi_connectors=$(drm_info 2>/dev/null | grep -i "hdmi\|dp" | head -5 || true)
    if [[ -n "$hdmi_connectors" ]]; then
        echo "$hdmi_connectors"
    fi
elif command -v xrandr &>/dev/null; then
    xrandr --query 2>/dev/null | grep -E "HDMI|DP.*connected" || true
fi

# Check sysfs for HDCP status
for connector in /sys/class/drm/*/status; do
    if [[ -f "$connector" ]]; then
        connector_name=$(basename $(dirname "$connector"))
        status=$(cat "$connector")
        if [[ "$status" == "connected" ]]; then
            hdcp_file="/sys/class/drm/${connector_name}/hdcp_content_type"
            if [[ -f "$hdcp_file" ]]; then
                hdcp_val=$(cat "$hdcp_file" 2>/dev/null || echo "unknown")
                check_hdcp_compliance "Connector: $connector_name" "$hdcp_val"
            fi
        fi
    fi
done

# 4. Check Monitor EDID for HDCP Support
echo -e "\n=== MONITOR EDID HDCP SUPPORT ==="

# Extract and parse EDID from connected displays
for edid_file in /sys/class/drm/*/edid; do
    if [[ -f "$edid_file" ]] && [[ -s "$edid_file" ]]; then
        connector=$(basename $(dirname "$edid_file"))

        # Check if connected
        if [[ ! -f "/sys/class/drm/${connector}/status" ]] || \
           [[ "$(cat /sys/class/drm/${connector}/status 2>/dev/null)" != "connected" ]]; then
            continue
        fi

        # Parse EDID for HDCP support (byte 120-127 contains extensions)
        # HDCP support info typically in extension blocks
        hexdump -C "$edid_file" 2>/dev/null | head -20 > /dev/null

        # Simplified check: look for HDCP support in EDID data
        edid_hex=$(hexdump -An -tx1 "$edid_file" 2>/dev/null | tr -d ' \n')

        # Check for HDCP capability byte (varies by EDID version/extension)
        if echo "$edid_hex" | grep -q "0290"; then
            check_hdcp_compliance "Monitor ($connector) EDID" "enabled"
        else
            # Unable to definitively parse EDID - may still support HDCP
            echo -e "${YELLOW}? Monitor ($connector) EDID: Unable to parse HDCP status${NC}"
        fi
    fi
done

# Summary
echo -e "\n=== SUMMARY ==="
if $COMPLIANT; then
    echo -e "${GREEN}All checked components appear HDCP compliant${NC}"
else
    echo -e "${RED}WARNING: One or more components are NOT HDCP compliant${NC}"
    exit 1
fi
