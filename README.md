# OBS Docker Setup

This project sets up an OBS Studio instance in a Docker container with **NoVNC web-based access** for GUI control and OBS WebSocket for external automation. Designed for Apple Silicon Macs to run x86_64 OBS with Advanced Scene Switcher plugin.

## Prerequisites

- Docker Desktop for Mac (with Rosetta enabled for x86_64 emulation)
- Modern web browser (Chrome, Firefox, Safari, Edge) - **No separate VNC client needed!**

## Environment Variables

Copy `.env.example` to `.env` and modify the values:

```bash
cp .env.example .env
# Edit .env with your preferred settings
```

> **Security Note**: The `.env` file is automatically excluded from version control via `.gitignore` to prevent accidentally committing sensitive configuration or passwords.

Available variables:
- `VNC_PORT`: VNC port for the instance (default: 5901)
- `NOVNC_PORT`: NoVNC web port for the instance (default: 6081)
- `OBS_WS_PASSWORD`: Password for OBS WebSocket (optional)
- `OBS_WS_PORT`: WebSocket port for external control (default: 4455)
- `OBS_BASE_WIDTH/OBS_BASE_HEIGHT`: Base (Canvas) resolution (default: 1920x1080)
- `OBS_OUTPUT_WIDTH/OBS_OUTPUT_HEIGHT`: Output (Scaled) resolution (default: 1920x1080)
- `OBS_SCALE_TYPE`: Video scaling method - bilinear, bicubic, lanczos, area (default: bicubic)
- `OBS_COLOR_FORMAT`: Color format - NV12, I420, I444, RGB (default: NV12)
- `OBS_COLOR_SPACE`: Color space - 601, 709 (default: 709)
- `OBS_COLOR_RANGE`: Color range - Full, Partial (default: Partial)
- `OBS_FPS_COMMON/OBS_FPS_INT`: FPS settings (default: 30)

## OBS Video Configuration

You can configure OBS video settings through environment variables. These settings are applied when the container starts, so you don't need to manually configure them through the OBS interface.

### Common Configurations:

**1080p (1920x1080) - Default:**
```bash
OBS_BASE_WIDTH=1920
OBS_BASE_HEIGHT=1080
OBS_OUTPUT_WIDTH=1920
OBS_OUTPUT_HEIGHT=1080
```

**4K (3840x2160):**
```bash
OBS_BASE_WIDTH=3840
OBS_BASE_HEIGHT=2160
OBS_OUTPUT_WIDTH=3840
OBS_OUTPUT_HEIGHT=2160
```

**720p (1280x720):**
```bash
OBS_BASE_WIDTH=1280
OBS_BASE_HEIGHT=720
OBS_OUTPUT_WIDTH=1280
OBS_OUTPUT_HEIGHT=720
```

### Advanced Settings:

- **Scale Type**: `bilinear` (fastest), `bicubic` (balanced), `lanczos` (highest quality)
- **Color Format**: `NV12` (recommended), `I420`, `I444`, `RGB`
- **Color Space**: `709` (HD), `601` (SD)
- **Color Range**: `Partial` (16-235), `Full` (0-255)
- **FPS**: Common values: 24, 25, 30, 60

### Example for 4K Streaming:

```bash
OBS_BASE_WIDTH=3840
OBS_BASE_HEIGHT=2160
OBS_OUTPUT_WIDTH=1920
OBS_OUTPUT_HEIGHT=1080
OBS_SCALE_TYPE=lanczos
OBS_FPS_COMMON=60
```

This sets up a 4K canvas that outputs at 1080p for streaming, using high-quality scaling and 60 FPS.

## Multi-Instance Setup

For running multiple OBS instances simultaneously, use the provided generation scripts:

### Quick Setup (Same Configuration)

```bash
# Generate docker-compose.yml with 6 instances
./generate-compose.sh 6

# Build and start all instances
docker-compose up -d
```

### Advanced Setup (Different Configurations per Instance)

```bash
# Edit instance-config.env to customize each instance
nano instance-config.env

# Generate docker-compose.yml with custom configurations
./generate-compose-advanced.sh 8 instance-config.env

# Build and start instances
docker-compose up -d
```

### Instance Management

Use the management script to control your instances:

```bash
# Show status of all instances
./manage-instances.sh status

# Start specific instances
./manage-instances.sh start 1 3 5

# Start instances and automatically open browsers
./manage-instances.sh start 1 2 --open

# Stop all instances
./manage-instances.sh stop

# Show resource usage
./manage-instances.sh resources

# View logs for instance 2
./manage-instances.sh logs 2

# Open browsers to specific instances
./manage-instances.sh open 1 3

# Open browsers to all running instances
./manage-instances.sh open
```

### Browser Auto-Open Feature

The management script includes automatic browser opening:

- **Individual instances**: `./manage-instances.sh open 1 2 3`
- **All instances**: `./manage-instances.sh open`
- **Auto-open on start**: `./manage-instances.sh start 1 2 --open`

The script automatically detects your OS and uses the appropriate command:
- **macOS**: `open`
- **Linux**: `xdg-open`
- **Windows**: `start`

### Quick Demo

```bash
# Generate 6 instances
./generate-compose.sh 6

# Start instances 1, 3, and 5 with auto-browser opening
./manage-instances.sh start 1 3 5 --open

# This will:
# 1. Start the specified instances
# 2. Wait for them to be ready
# 3. Automatically open browser tabs to:
#    - http://localhost:6081 (Instance 1)
#    - http://localhost:6083 (Instance 3)  
#    - http://localhost:6085 (Instance 5)
```

### Port Assignment

Each instance gets automatically assigned unique ports:

- **Instance 1**: VNC: 5901, NoVNC: 6081, WebSocket: 4455
- **Instance 2**: VNC: 5902, NoVNC: 6082, WebSocket: 4456
- **Instance N**: VNC: 5900+N, NoVNC: 6080+N, WebSocket: 4454+N