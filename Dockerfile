# Use Ubuntu 22.04 Jammy for Qt6 support
FROM --platform=linux/amd64 ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV OBS_WS_PASSWORD=
ENV USER=root

# Update and install minimal base dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    wget \
    curl \
    gnupg \
    python3 \
    python3-numpy \
    websockify \
    x11vnc \
    xvfb \
    x11-utils \
    x11-xserver-utils \
    xfonts-base \
    xfonts-75dpi \
    xfonts-100dpi \
    fluxbox \
    xterm \
    && rm -rf /var/lib/apt/lists/*

# Add OBS Studio PPA and install OBS (Jammy version)
RUN add-apt-repository ppa:obsproject/obs-studio \
    && apt-get update \
    && apt-get install -y obs-studio \
    && rm -rf /var/lib/apt/lists/*

# Install build dependencies for Advanced Scene Switcher
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    qt6-base-dev \
    qt6-tools-dev \
    libxss-dev \
    libxtst-dev \
    libxrandr-dev \
    libxcomposite-dev \
    libxdamage-dev \
    libxfixes-dev \
    libxinerama-dev \
    libxkbcommon-dev \
    pkg-config \
    wget \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    nlohmann-json3-dev \
    libcurl4-openssl-dev \
    libopencv-dev \
    && rm -rf /var/lib/apt/lists/*

# Install newer CMake (required for SceneSwitcher)
RUN apt-get update \
    && apt-get install -y cmake \
    && rm -rf /var/lib/apt/lists/*

# Download and install Advanced Scene Switcher from pre-built release
RUN wget https://github.com/WarmUpTill/SceneSwitcher/releases/download/1.24.2/advanced-scene-switcher-linux-x86_64.deb \
    && dpkg -i advanced-scene-switcher-linux-x86_64.deb \
    && rm advanced-scene-switcher-linux-x86_64.deb

# Download and install NoVNC
RUN wget https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz \
    && tar -xzf v1.4.0.tar.gz \
    && mv noVNC-1.4.0 /opt/noVNC \
    && rm v1.4.0.tar.gz \
    && ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Configure NoVNC for auto-connect
RUN sed -i 's/WebUtil.getConfigVar('\''autoconnect'\'', false)/true/' /opt/noVNC/vnc.html

# Create VNC directory and set up password
RUN mkdir -p /root/.vnc

# Copy Fluxbox configuration files
COPY fluxbox-config/ /root/.fluxbox/

# Copy startup script
COPY startup.sh /root/start.sh
RUN chmod +x /root/start.sh

# Expose VNC port (default 5901)
EXPOSE 5901

# Expose NoVNC web port (default 6080)
EXPOSE 6080

# Expose OBS WebSocket port (default 4455)
EXPOSE 4455

# Start VNC and OBS
CMD ["/root/start.sh"]