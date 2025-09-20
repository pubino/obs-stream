#!/bin/bash

# Set up environment
export DISPLAY=:1
export XAUTHORITY=/root/.Xauthority

# Clean up any existing X locks
rm -f /tmp/.X1-lock
rm -f /tmp/.X11-unix/X1

# Create X authority file
touch /root/.Xauthority
xauth add :1 . $(openssl rand -hex 16)

# Start Xvfb with proper error handling
echo "Starting Xvfb..."
Xvfb :1 -screen 0 1280x720x24 &
XVFB_PID=$!

# Wait for Xvfb to be ready
sleep 3

# Check if Xvfb is still running
if ! kill -0 $XVFB_PID 2>/dev/null; then
    echo "Xvfb failed to start"
    exit 1
fi

# Start fluxbox window manager
echo "Starting fluxbox..."
fluxbox &
FLUXBOX_PID=$!

# Wait a bit for fluxbox to start
sleep 2

# Start x11vnc server
echo "Starting x11vnc..."
x11vnc -display :1 -nopw -forever -shared -rfbport 5901 &
X11VNC_PID=$!

# Wait for x11vnc to be ready
sleep 2

# Start websockify proxy for NoVNC
echo "Starting websockify proxy..."
websockify --web=/opt/noVNC 6080 localhost:5901 &
WEBSOCKIFY_PID=$!

# Wait for websockify to be ready
sleep 2

# Configure OBS settings from environment variables
echo "Configuring OBS settings..."

# Create OBS config directory structure if it doesn't exist
mkdir -p /root/.config/obs-studio/basic/profiles/Untitled
mkdir -p /root/.config/obs-studio/basic/scenes

# Configure basic.ini with video settings for the Untitled profile
cat > /root/.config/obs-studio/basic/profiles/Untitled/basic.ini << EOF
[General]
Name=Untitled

[Video]
BaseCX=${OBS_BASE_WIDTH:-1920}
BaseCY=${OBS_BASE_HEIGHT:-1080}
OutputCX=${OBS_OUTPUT_WIDTH:-1920}
OutputCY=${OBS_OUTPUT_HEIGHT:-1080}
ScaleType=${OBS_SCALE_TYPE:-bicubic}
ColorFormat=${OBS_COLOR_FORMAT:-NV12}
ColorSpace=${OBS_COLOR_SPACE:-709}
ColorRange=${OBS_COLOR_RANGE:-Partial}
FPSCommon=${OBS_FPS_COMMON:-30}
FPSInt=${OBS_FPS_INT:-30}
EOF

# Update global.ini to use Default profile and set video settings
cat > /root/.config/obs-studio/global.ini << EOF
[General]
Pre19Defaults=false
Pre21Defaults=false
Pre23Defaults=false
Pre24.1Defaults=false
MaxLogs=10
InfoIncrement=1
ProcessPriority=Normal
EnableAutoUpdates=true
ConfirmOnExit=true
HotkeyFocusType=NeverDisableHotkeys
FirstRun=false

[Video]
Renderer=OpenGL

[BasicWindow]
PreviewEnabled=true
PreviewProgramMode=false
SceneDuplicationMode=true
SwapScenesMode=true
SnappingEnabled=true
ScreenSnapping=true
SourceSnapping=true
CenterSnapping=false
SnapDistance=10
SpacingHelpersEnabled=true
RecordWhenStreaming=false
KeepRecordingWhenStreamStops=false
SysTrayEnabled=true
SysTrayWhenStarted=false
SaveProjectors=false
ShowTransitions=true
ShowListboxToolbars=true
ShowStatusBar=true
ShowSourceIcons=true
ShowContextToolbars=true
StudioModeLabels=true
VerticalVolControl=false
MultiviewMouseSwitch=true
MultiviewDrawNames=true
MultiviewDrawAreas=true
MediaControlsCountdownTimer=true

[Basic]
Profile=Untitled
ProfileDir=Untitled
SceneCollection=Untitled
SceneCollectionFile=Untitled
ConfigOnNewProfile=true
EOF

# Start OBS Studio
echo "Starting OBS Studio..."
obs --disable-shutdown-check --multiinstance &
OBS_PID=$!

# Function to handle shutdown
cleanup() {
    echo "Shutting down services..."
    kill $OBS_PID 2>/dev/null
    kill $WEBSOCKIFY_PID 2>/dev/null
    kill $X11VNC_PID 2>/dev/null
    kill $FLUXBOX_PID 2>/dev/null
    kill $XVFB_PID 2>/dev/null
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Monitor processes and restart if needed
while true; do
    # Check if Xvfb is still running
    if ! kill -0 $XVFB_PID 2>/dev/null; then
        echo "Xvfb died, restarting..."
        Xvfb :1 -screen 0 1280x720x24 &
        XVFB_PID=$!
        sleep 2
    fi

    # Check if fluxbox is still running
    if ! kill -0 $FLUXBOX_PID 2>/dev/null; then
        echo "Fluxbox died, restarting..."
        fluxbox &
        FLUXBOX_PID=$!
        sleep 1
    fi

    # Check if x11vnc is still running
    if ! kill -0 $X11VNC_PID 2>/dev/null; then
        echo "x11vnc died, restarting..."
        x11vnc -display :1 -nopw -forever -shared -rfbport 5901 &
        X11VNC_PID=$!
        sleep 1
    fi

    # Check if websockify is still running
    if ! kill -0 $WEBSOCKIFY_PID 2>/dev/null; then
        echo "websockify died, restarting..."
        websockify --web=/opt/noVNC 6080 localhost:5901 &
        WEBSOCKIFY_PID=$!
        sleep 1
    fi

    # Check if OBS is still running
    if ! kill -0 $OBS_PID 2>/dev/null; then
        echo "OBS died, restarting..."
        obs --disable-shutdown-check --multiinstance &
        OBS_PID=$!
        sleep 2
    fi

    sleep 5
done