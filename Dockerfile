FROM ubuntu:latest

ENV TZ=Europe/Berlin

RUN apt-get update && \
    apt-get install -y samba tzdata wget

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

RUN wget https://github.com/PowerShell/PowerShell/releases/download/v7.3.9/powershell-7.3.9-linux-arm64.tar.gz && \
    mkdir -p /opt/powershell && \
    tar -xvf powershell-7.3.9-linux-arm64.tar.gz -C /opt/powershell && \
    rm powershell-7.3.9-linux-arm64.tar.gz

ENV PATH="${PATH}:/opt/powershell"

SHELL ["pwsh" , "-command"]

RUN Install-Module -Name powershell-yaml -Force

ADD ./init.ps1 /init.ps1
ADD ./AddSambaUser.sh /AddSambaUser.sh

RUN chmod +x AddSambaUser.sh

EXPOSE 137/udp 138/udp 139 445

HEALTHCHECK --interval=60s --timeout=15s CMD smbclient -L \\localhost -U % -m SMB3

ENTRYPOINT [ "pwsh" ]
CMD ["./init.ps1", "-FilePath", "/config/config.yml", "-ValidateSmbConf", "-NoExit", "-StartSambaServer"]
