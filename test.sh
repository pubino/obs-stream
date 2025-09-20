#!/bin/bash

# Unit tests for OBS Docker container
# Run this script inside the container after build

echo "Running unit tests..."

# Test 1: Check if OBS is installed
if dpkg -l | grep -q obs-studio; then
    echo "✓ OBS Studio is installed"
else
    echo "✗ OBS Studio is NOT installed"
    exit 1
fi

# Test 2: Check if Advanced Scene Switcher is installed
if dpkg -l | grep -q advanced-scene-switcher; then
    echo "✓ Advanced Scene Switcher is installed"
else
    echo "✗ Advanced Scene Switcher is NOT installed"
    exit 1
fi

# Test 3: Check if OBS WebSocket plugin is installed
if [ -f /usr/lib/x86_64-linux-gnu/obs-plugins/obs-websocket.so ]; then
    echo "✓ OBS WebSocket plugin is installed"
else
    echo "✗ OBS WebSocket plugin is NOT installed"
    exit 1
fi

# Test 4: Check if websockify is installed
if dpkg -l | grep -q websockify; then
    echo "✓ websockify is installed"
else
    echo "✗ websockify is NOT installed"
    exit 1
fi

# Test 5: Check if NoVNC is installed
if [ -d /opt/noVNC ]; then
    echo "✓ NoVNC is installed"
else
    echo "✗ NoVNC is NOT installed"
    exit 1
fi

# Test 6: Check if fluxbox is installed
if dpkg -l | grep -q fluxbox; then
    echo "✓ fluxbox window manager is installed"
else
    echo "✗ fluxbox window manager is NOT installed"
    exit 1
fi

# Test 7: Check NoVNC web interface files exist
if [ -f /opt/noVNC/vnc.html ] && [ -f /opt/noVNC/index.html ]; then
    echo "✓ NoVNC web interface files exist"
else
    echo "✗ NoVNC web interface files do NOT exist"
    exit 1
fi

# Test 8: Check startup script exists and is executable
if [ -x /root/start.sh ]; then
    echo "✓ Startup script exists and is executable"
else
    echo "✗ Startup script does NOT exist or is not executable"
    exit 1
fi

# Test 9: Check if websockify proxy is running (functional test)
if pgrep -f "websockify" > /dev/null; then
    echo "✓ websockify proxy is running"
else
    echo "✗ websockify proxy is NOT running"
    exit 1
fi

# Test 10: Check if OBS can run (brief test)
timeout 5 obs --version > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ OBS can execute"
else
    echo "✗ OBS cannot execute"
    exit 1
fi

echo "All tests passed! 🎉"