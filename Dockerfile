FROM ubuntu:focal

RUN DEBIAN_FRONTEND=noninteractive ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime

RUN DEBIAN_FRONTEND=noninteractive apt update \
    && apt install -y --no-install-recommends software-properties-common curl gpg-agent \
    && curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
    && apt-add-repository -y ppa:ansible/ansible \
    && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com focal main" \
    && apt update && apt upgrade -y && apt install -y sshpass \
    && apt -y --no-install-recommends install python3.8 telnet curl openssh-client nano vim-tiny \
    iputils-ping build-essential libssl-dev libffi-dev python3-pip \
    python3-setuptools python3-wheel python3-netmiko net-tools ansible terraform \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install pyntc \
    && pip3 install napalm \
    && mkdir /root/.ssh/ \
    && echo "KexAlgorithms diffie-hellman-group1-sha1,curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha256,diffie-hellman-group14-sha1" > /root/.ssh/config \
    && echo "Ciphers 3des-cbc,aes128-cbc,aes128-ctr,aes256-ctr" >> /root/.ssh/config \
    && chown -R root /root/.ssh/ \
    && ln -sf /usr/bin/python3.8 /usr/bin/python3

VOLUME [ "/root", "/etc", "/usr" ]

# install google chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' \
    && apt-get -y update && apt-get install -y google-chrome-stable \
    && apt-get install -y udev && apt-get install -y xvfb

# install chromedriver
RUN apt-get install -yqq unzip
RUN wget -O /tmp/chromedriver.zip http://chromedriver.storage.googleapis.com/`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE`/chromedriver_linux64.zip
RUN unzip /tmp/chromedriver.zip chromedriver -d /usr/local/bin/

# set display port to avoid crash
ENV DISPLAY=:99

RUN pip install --no-cache-dir \
  robotframework \
  robotframework-seleniumlibrary==4.3.0 \
  pyyaml \
  selenium

# Chrome requires docker to have cap_add: SYS_ADMIN if sandbox is on.
# Disabling sandbox and gpu as default.
RUN sed -i "s/self._arguments\ =\ \[\]/self._arguments\ =\ \['--no-sandbox',\ '--disable-gpu'\]/" /usr/local/lib/python3.7/site-packages/selenium/webdriver/chrome/options.py

COPY entry_point.sh /opt/bin/entry_point.sh
RUN chmod +x /opt/bin/entry_point.sh

ENV SCREEN_WIDTH 1280
ENV SCREEN_HEIGHT 720
ENV SCREEN_DEPTH 16

ENTRYPOINT [ "/opt/bin/entry_point.sh" ]
