FROM kalilinux/kali-rolling:latest

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update system and install the official Kali Xfce Desktop environment, 
# VNC server, noVNC web interface, sudo utilities, and system prerequisites
RUN apt-get update && apt-get install -y \
    kali-desktop-xfce \
    tigervnc-standalone-server \
    novnc \
    websockify \
    wget \
    curl \
    dbus-x11 \
    gnupg \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Download and install official Google Chrome stable version
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get update \
    && apt-get install -y ./google-chrome-stable_current_amd64.deb \
    && rm google-chrome-stable_current_amd64.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create the user 'hux', set up their home directory, and grant full admin (sudo) rights without password prompts
RUN useradd -m -s /bin/bash hux \
    && usermod -aG sudo hux \
    && echo "hux ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set the system password for the root user account
RUN echo "root:kali2026" | chpasswd

# Switch from root execution context over to our new admin user context
USER hux
ENV USER=hux
ENV HOME=/home/hux
ENV DISPLAY=:1
ENV VNC_RESOLUTION=1280x720

# Create required modern configuration directories for TigerVNC inside hux's home
RUN mkdir -p /home/hux/.config/tigervnc \
    && echo "#!/bin/sh\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
startxfce4 &" > /home/hux/.config/tigervnc/xstartup \
    && chmod +x /home/hux/.config/tigervnc/xstartup

# Set a default VNC password directly inside the modern path
RUN echo "kali2026" | vncpasswd -f > /home/hux/.config/tigervnc/passwd \
    && chmod 600 /home/hux/.config/tigervnc/passwd

# Expose port 8080 for the noVNC browser connection route
EXPOSE 8080

# Start script to initiate VNC server under user 'hux' and proxy it over noVNC
CMD ["sh", "-c", "vncserver :1 -geometry $VNC_RESOLUTION -depth 24 && websockify --web /usr/share/novnc/ 8080 localhost:5901"]
