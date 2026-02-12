# XMRig Quadlet

A Tor secured XMRig client managed by Podman Quadlet.

## Features

- All XMRig traffic must go through Tor
  - XMRig container -> Internal network -> Tor proxy container -> External network (internet)
- Automatically rebuilds images from upstream
  - XMRig: weekly
  - Tor: daily
- Automatically restarts when a new image is built
- Automatically starts/stops on reboot
- No updates required unless upstream introduces breaking changes
- Minimal image size:
  - XMRig: ~15MB
  - Tor: ~160MB
- Optional CLI and desktop toggle for persistent enable/disable

## Requirements

- Linux
- Podman

## Install

### Download the project

#### Default XMRig branch

```bash
git clone --recurse-submodules https://github.com/president-not-sure/xmrig-quadlet.git
cd xmrig-quadlet
```

#### MoneroOcean pool (https://moneroocean.stream) XMRig branch

```bash
git clone --recurse-submodules --branch moneroocean https://github.com/president-not-sure/xmrig-quadlet.git
cd xmrig-quadlet
```

### config.json

1. Generate a `config.json` using this wizard `https://xmrig.com/wizard`.
2. `sudo mkdir -p /etc/xmrig`
3. Copy it to `/etc/xmrig`.

#### Minimal `config.json` example

```json
{
    "autosave": true,
    "cpu": true,
    "opencl": false,
    "cuda": false,
    "pools": [
        {
            "coin": "monero",
            "algo": null,
            "url": "pooladdress.onion:port",
            "user": "wallet_address",
            "pass": "worker_name",
            "tls": false,
            "socks5": "xmrig-tor:9050",
            "keepalive": true,
            "nicehash": false
        }
    ]
}

```

### Core App

```bash
sudo podman quadlet install --replace tor-quadlet/tor
sudo podman quadlet install --replace xmrig
sudo install -vD -m 644 -t /etc/systemd/system \
    tor-quadlet/timers/tor-build.timer \
    timers/xmrig-build.timer
sudo systemctl daemon-reload
sudo systemctl enable --now \
    tor-build.timer \
    xmrig-build.timer \
    podman-auto-update.timer
```

> [!IMPORTANT]
> Ensure network/container IP addresses are unique on this host.

> [!NOTE]
> If the host runs a DNS server on all interfaces, add `DisableDNS=true` under the `[Network]` section of each `.network` unit file to prevent port conflicts on UDP 53.

> [!NOTE]
> The minimum donation percentage has been reduced to 0 via a patch, but the default has been kept at 1. This means that you can adjust it to 0 in the config.json or the command line.

### Quick On/Off Toggle

```bash
sudo install -vD -m 0755 -t /usr/local/bin toggle/xmrig
install -vD -m 0644 -t ~/.local/share/applications toggle/xmrig.desktop
```

> [!NOTE]
> - The first run will take more time because it needs to build the first image. `journalctl -f -u xmrig-build.service` to see build progress.
> - `sudo podman logs --follow xmrig` or any Podman GUI for XMRig logs.

## Uninstall

```bash
sudo systemctl unmask xmrig.service
sudo systemctl stop xmrig.service
sudo podman quadlet rm --force .tor.app
sudo podman quadlet rm --force .xmrig.app
sudo systemctl disable --now tor-build.timer xmrig-build.timer
sudo rm -rfv \
    /etc/systemd/system/xmrig-build.timer \
    /etc/systemd/system/tor-build.timer \
    /usr/local/bin/xmrig \
    ~/.local/share/applications/xmrig.desktop
sudo systemctl daemon-reload
```

## Troubleshooting

If encountering this error/warning:

```
kernel: Lockdown: xmrig: raw MSR access is restricted; see man kernel_lockdown.7
```

Fix:

https://github.com/xmrig/xmrig/blob/master/doc/CPU.md#wrmsr
