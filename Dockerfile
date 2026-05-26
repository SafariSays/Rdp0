FROM ubuntu:24.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update system and install XFCE desktop, VNC server, noVNC, and utilities
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    novnc \
    websockify \
    curl \
    git \
    python3 \
    && apt-get clean

# Set up the VNC configuration directory
RUN mkdir -p /root/.vnc \
    && echo "#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nstartxfce4 &" > /root/.vnc/xstartup \
    && chmod +x /root/.vnc/xstartup

# Inform Docker about port communication (Railway handles the actual mapping via $PORT)
EXPOSE 8080

# Start the VNC server, then launch the noVNC proxy listening on Railway's dynamic PORT
CMD vncserver :1 -geometry 1280x800 -depth 24 -SecurityTypes None && \
    /usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen ${PORT:-8080}
