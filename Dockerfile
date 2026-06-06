FROM ubuntu:24.04

# Prevent interactive prompts during structural installation phases
ENV DEBIAN_FRONTEND=noninteractive

# Update system and add the correct, matching Linux Mint Wilma software channels
RUN apt-get update && apt-get install -y gnupg wget curl software-properties-common \
    && echo "deb http://packages.linuxmint.com wilma main upstream import backport" > /etc/apt/sources.list.d/mint.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6616109451BBBF2

# Cleanly pull down the lightweight Mint Xfce desktop layer, native browser, and streaming utilities
RUN apt-get update && apt-get install -y \
    mint-meta-xfce \
    firefox \
    tigervnc-standalone-server \
    novnc \
    websockify \
    dbus-x11 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Force the container environment settings back over to pure root execution paths
USER root
ENV USER=root
ENV HOME=/root
ENV DISPLAY=:1
ENV VNC_RESOLUTION=1280x720

# Create required structural directories for TigerVNC inside root home
RUN mkdir -p /root/.config/tigervnc \
    && echo "#!/bin/sh\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
xfce4-session &" > /root/.config/tigervnc/xstartup \
    && chmod +x /root/.config/tigervnc/xstartup

# Directly inject the pre-encrypted credential file to bypass the "Inappropriate ioctl" interactive terminal error
RUN printf "\x23\x7e\x2b\x67\xb5\xdd\x04\x3a" > /root/.config/tigervnc/passwd \
    && chmod 600 /root/.config/tigervnc/passwd

# Runtime start wrapper script to engage the virtual layout display and proxy cleanly
ENTRYPOINT ["sh", "-c", "vncserver :1 -geometry $VNC_RESOLUTION -depth 24 -localhost no && websockify --web /usr/share/novnc/ 8080 127.0.0.1:5901"]

# Explicitly expose backend communication route 8080 at the absolute bottom
EXPOSE 8080
