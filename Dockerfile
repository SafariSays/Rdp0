FROM --platform=linux/amd64 kalilinux/kali-rolling:latest
# Prevent any interactive frontend freezing prompts during building
ENV DEBIAN_FRONTEND=noninteractive
ENV NEEDRESTART_MODE=a

# 1. Clear out apt caches and update mirrors smoothly
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    kali-desktop-xfce \
    tigervnc-standalone-server \
    novnc \
    websockify \
    wget \
    curl \
    dbus-x11 \
    gnupg \
    sudo \
    ca-certificates \
    software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. Native Google Chrome Installation (Avoids Snap altogether)
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/debian/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# --- DOWNWARD STRUCTURAL CONFIGURATIONS ---

# Set up environment variables for root context
ENV USER=root
ENV HOME=/root
ENV DISPLAY=:1

# Ensure .Xauthority exists to avoid display initialization errors
RUN touch /root/.Xauthority

# Configure the Xfce session startup script cleanly
RUN mkdir -p /root/.vnc \
    && echo "#!/bin/sh\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
startxfce4 &" > /root/.vnc/xstartup \
    && chmod +x /root/.vnc/xstartup

# Expose VNC and web-browser noVNC ports
EXPOSE 5901
EXPOSE 6080

# Boot script: Bypasses password checks, creates a quick secure-token, launches web view
CMD ["bash", "-c", "vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 --I-KNOW-THIS-IS-INSECURE && openssl req -new -subj '/C=JP' -x509 -days 365 -nodes -out self.pem -keyout self.pem && websockify -D --web=/usr/share/novnc/ --cert=self.pem 6080 localhost:5901 && tail -f /dev/null"]
