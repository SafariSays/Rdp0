FROM kalilinux/kali-rolling:latest

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update system and install the official Kali Xfce Desktop environment, 
# Firefox browser, VNC server, noVNC web interface, and system prerequisites
RUN apt-get update && apt-get install -y \
    kali-desktop-xfce \
    firefox-esr \
    tigervnc-standalone-server \
    novnc \
    websockify \
    wget \
    curl \
    dbus-x11 \
    gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Revert execution context completely back to root
USER root
ENV USER=root
ENV HOME=/root
ENV DISPLAY=:1
ENV VNC_RESOLUTION=1280x720

# Create required modern configuration directories for TigerVNC directly inside root home
RUN mkdir -p /root/.config/tigervnc \
    && echo "#!/bin/sh\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
startxfce4 &" > /root/.config/tigervnc/xstartup \
    && chmod +x /root/.config/tigervnc/xstartup

# Set a default VNC password for the root desktop session (Default: kali2026)
RUN echo "kali2026" | vncpasswd -f > /root/.config/tigervnc/passwd \
    && chmod 600 /root/.config/tigervnc/passwd

# Start script to initiate VNC server under root and proxy it over noVNC safely
ENTRYPOINT ["sh", "-c", "vncserver :1 -geometry $VNC_RESOLUTION -depth 24 -localhost no && websockify --web /usr/share/novnc/ 8080 127.0.0.1:5901"]

# Expose network port 8080 at the very end of the file structure
EXPOSE 8080
