FROM ubuntu:26.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system utilities and add the official Linux Mint repositories
# (Note: Using 'wilma' packages which layer perfectly onto the new LTS base structure)
RUN apt-get update && apt-get install -y gnupg wget curl software-properties-common \
    && echo "deb http://packages.linuxmint.com wilma main upstream import backport" > /etc/apt/sources.list.d/mint.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6616109451BBBF2

# Update package tree and install the Linux Mint Xfce core desktop environment,
# Firefox, TigerVNC server, and noVNC web streaming tools
RUN apt-get update && apt-get install -y \
    mint-meta-xfce \
    firefox \
    tigervnc-standalone-server \
    novnc \
    websockify \
    dbus-x11 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Keep everything running safely as root to avoid folder creation blocks
USER root
ENV USER=root
ENV HOME=/root
ENV DISPLAY=:1
ENV VNC_RESOLUTION=1280x720

# Create required modern configuration directories for TigerVNC inside root home
RUN mkdir -p /root/.config/tigervnc \
    && echo "#!/bin/sh\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
xfce4-session &" > /root/.config/tigervnc/xstartup \
    && chmod +x /root/.config/tigervnc/xstartup

# Set a default VNC access password (Change 'mint2026' to whatever password you want)
RUN echo "mint2026" | vncpasswd -f > /root/.config/tigervnc/passwd \
    && chmod 600 /root/.config/tigervnc/passwd

# Runtime start command to run TigerVNC server and proxy it clean to your browser
ENTRYPOINT ["sh", "-c", "vncserver :1 -geometry $VNC_RESOLUTION -depth 24 -localhost no && websockify --web /usr/share/novnc/ 8080 127.0.0.1:5901"]

# Expose network port 8080 at the bottom for Railway routing integration
EXPOSE 8080
