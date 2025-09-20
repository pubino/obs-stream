#!/bin/bash

# Script to generate docker-compose.yml with multiple OBS instances
# Usage: ./generate-compose.sh [number_of_instances]

NUM_INSTANCES=${1:-1}

cat > docker-compose.yml << EOF
version: '3.8'

services:
EOF

# Generate services
for i in $(seq 1 $NUM_INSTANCES); do
    VNC_PORT=$((5900 + i))
    NOVNC_PORT=$((6080 + i))
    WS_PORT=$((4454 + i))

    cat >> docker-compose.yml << EOF
  obs-instance-${i}:
    build: .
    ports:
      - "${VNC_PORT}:${VNC_PORT}"
      - "${NOVNC_PORT}:6080"
      - "${WS_PORT}:4455"
    environment:
      - VNC_PORT=${VNC_PORT}
      - NOVNC_PORT=${NOVNC_PORT}
      - OBS_WS_PORT=${WS_PORT}
      - OBS_BASE_WIDTH=\${OBS_BASE_WIDTH:-1920}
      - OBS_BASE_HEIGHT=\${OBS_BASE_HEIGHT:-1080}
      - OBS_OUTPUT_WIDTH=\${OBS_OUTPUT_WIDTH:-1920}
      - OBS_OUTPUT_HEIGHT=\${OBS_OUTPUT_HEIGHT:-1080}
      - OBS_SCALE_TYPE=\${OBS_SCALE_TYPE:-bicubic}
      - OBS_COLOR_FORMAT=\${OBS_COLOR_FORMAT:-NV12}
      - OBS_COLOR_SPACE=\${OBS_COLOR_SPACE:-709}
      - OBS_COLOR_RANGE=\${OBS_COLOR_RANGE:-Partial}
      - OBS_FPS_COMMON=\${OBS_FPS_COMMON:-30}
      - OBS_FPS_INT=\${OBS_FPS_INT:-30}
    volumes:
      - obs-data-${i}:/root/.config/obs-studio
    restart: unless-stopped

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
echo "Ports used:"
for i in $(seq 1 $NUM_INSTANCES); do
    VNC_PORT=$((5900 + i))
    NOVNC_PORT=$((6080 + i))
    WS_PORT=$((4454 + i))
    echo "  Instance $i: VNC=${VNC_PORT}, NoVNC=${NOVNC_PORT}, WebSocket=${WS_PORT}"
done