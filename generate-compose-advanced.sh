#!/bin/bash

# Advanced script to generate docker-compose.yml with configurable OBS instances
# Usage: ./generate-compose-advanced.sh [number_of_instances] [config_file]

NUM_INSTANCES=${1:-1}
CONFIG_FILE=${2:-"instance-config.env"}

# Default configurations
declare -A INSTANCE_CONFIGS

# Load instance-specific configurations if config file exists
if [ -f "$CONFIG_FILE" ]; then
    echo "Loading configurations from $CONFIG_FILE"
    source "$CONFIG_FILE"
fi

# Function to get instance config value
get_instance_config() {
    local instance=$1
    local setting=$2
    local default=$3
    local var_name="INSTANCE_${instance}_${setting}"

    # Use indirect variable expansion
    eval "value=\${$var_name:-$default}"
    echo "$value"
}

# Generate docker-compose.yml
cat > docker-compose.yml << EOF
version: '3.8'

services:
EOF

# Generate services
for i in $(seq 1 $NUM_INSTANCES); do
    VNC_PORT=$((5900 + i))
    NOVNC_PORT=$((6080 + i))
    WS_PORT=$((4454 + i))

    # Get instance-specific config or use defaults
    BASE_WIDTH=$(get_instance_config $i "BASE_WIDTH" 1920)
    BASE_HEIGHT=$(get_instance_config $i "BASE_HEIGHT" 1080)
    OUTPUT_WIDTH=$(get_instance_config $i "OUTPUT_WIDTH" 1920)
    OUTPUT_HEIGHT=$(get_instance_config $i "OUTPUT_HEIGHT" 1080)
    SCALE_TYPE=$(get_instance_config $i "SCALE_TYPE" "bicubic")
    FPS=$(get_instance_config $i "FPS" 30)

    cat >> docker-compose.yml << EOF
  obs-instance-${i}:
    build: .
    container_name: obs-instance-${i}
    ports:
      - "${VNC_PORT}:${VNC_PORT}"
      - "${NOVNC_PORT}:6080"
      - "${WS_PORT}:4455"
    environment:
      - VNC_PORT=${VNC_PORT}
      - NOVNC_PORT=${NOVNC_PORT}
      - OBS_WS_PORT=${WS_PORT}
      - OBS_BASE_WIDTH=${BASE_WIDTH}
      - OBS_BASE_HEIGHT=${BASE_HEIGHT}
      - OBS_OUTPUT_WIDTH=${OUTPUT_WIDTH}
      - OBS_OUTPUT_HEIGHT=${OUTPUT_HEIGHT}
      - OBS_SCALE_TYPE=${SCALE_TYPE}
      - OBS_COLOR_FORMAT=NV12
      - OBS_COLOR_SPACE=709
      - OBS_COLOR_RANGE=Partial
      - OBS_FPS_COMMON=${FPS}
      - OBS_FPS_INT=${FPS}
    volumes:
      - obs-data-${i}:/root/.config/obs-studio
    restart: unless-stopped
    labels:
      - "instance=${i}"
      - "resolution=${BASE_WIDTH}x${BASE_HEIGHT}"
      - "fps=${FPS}"

EOF
done

# Generate volumes section
cat >> docker-compose.yml << EOF

volumes:
EOF

for i in $(seq 1 $NUM_INSTANCES); do
    cat >> docker-compose.yml << EOF
  obs-data-${i}:
EOF
done

echo "Generated docker-compose.yml with $NUM_INSTANCES OBS instances"
echo ""
echo "Instance Summary:"
for i in $(seq 1 $NUM_INSTANCES); do
    VNC_PORT=$((5900 + i))
    NOVNC_PORT=$((6080 + i))
    WS_PORT=$((4454 + i))

    BASE_WIDTH=$(get_instance_config $i "BASE_WIDTH" 1920)
    BASE_HEIGHT=$(get_instance_config $i "BASE_HEIGHT" 1080)
    FPS=$(get_instance_config $i "FPS" 30)

    echo "  Instance $i:"
    echo "    Web Access: http://localhost:${NOVNC_PORT}"
    echo "    VNC: localhost:${VNC_PORT}"
    echo "    WebSocket: localhost:${WS_PORT}"
    echo "    Resolution: ${BASE_WIDTH}x${BASE_HEIGHT} @ ${FPS} FPS"
    echo ""
done