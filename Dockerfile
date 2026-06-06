FROM --platform=linux/amd64 ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install core Xfce desktop, TigerVNC, noVNC, and system essentials
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    sudo \
    xterm \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps \
    wget \
    curl \
    git \
    gnupg \
    software-properties-common \
    && apt-get clean

# Add the official Linux Mint repository cleanly just for native themes and artwork icons
RUN echo "deb http://packages.linuxmint.com wilma main upstream import backport" > /etc/apt/sources.list.d/mint.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6616109451BBBF2 \
    && apt update -y \
    && apt install -y mint-themes mint-x-icons mint-y-icons \
    && apt-get clean

# Install real Firefox via the Mozilla Team PPA repository
RUN add-apt-repository ppa:mozillateam/ppa -y \
    && echo 'Package: *' >> /etc/apt/preferences.d/mozilla-firefox \
    && echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox \
    && echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox \
    && apt update -y && apt install -y firefox

# Setup the standard headless X-authority mapping file
RUN touch /root/.Xauthority

# Configure the modern TigerVNC startup path to launch the graphical desktop layout
RUN mkdir -p /root/.config/tigervnc \
    && echo "#!/bin/sh\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
startxfce4 &" > /root/.config/tigervnc/xstartup \
    && chmod +x /root/.config/tigervnc/xstartup

# Run the system boot script: Generates SSL keys, opens TigerVNC securely without internal prompts, 
# and links it to port 8080 (which matches your dynamic web routing on Railway)
CMD bash -c "vncserver :1 -localhost no -SecurityTypes None -geometry 1280x720 --I-KNOW-THIS-IS-INSECURE && openssl req -new -subj '/C=US' -x509 -days 365 -nodes -out self.pem -keyout self.pem && websockify --web=/usr/share/novnc/ --cert=self.pem 8080 localhost:5901 && tail -f /dev/null"
