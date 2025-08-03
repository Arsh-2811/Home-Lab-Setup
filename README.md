# My Home Lab Setup

This repository contains the configuration for my personal home lab, which is managed primarily with Docker and Docker Compose. It includes a variety of self-hosted services for media management, network-wide ad blocking, reverse proxying, and more. The goal of this setup is to be easy to manage, scalable, and well-documented.

## ✨ Features

  * **Automated Media Management**: A full media stack including Sonarr, Radarr, Prowlarr, Jellyseerr, and qBittorrent, all routed through a VPN for privacy.
  * **Media Streaming**: Jellyfin for streaming media to various devices on the local network.
  * **Centralized Dashboard**: A beautiful and functional dashboard using [Homepage](https://gethomepage.dev/) to access all services from one place.
  * **Network-wide Ad Blocking**: Pi-hole for blocking ads and trackers on all devices on the network.
  * **Reverse Proxy**: Nginx Proxy Manager for easy and secure access to services with SSL certificates.
  * **Photo Management**: Immich for self-hosting and managing a personal photo library.
  * **Simple Script Execution**: Olivetin for running management scripts directly from a web UI.
  * **Easy to Deploy**: The entire stack can be started or stopped with simple shell scripts.

## 🛠️ Services Included

The services are organized into different stacks within this repository.

### Media Stack (`media-stack/`)

| Service | Description |
| :--- | :--- |
| **Jellyfin** | A free software media system for streaming and managing media. |
| **Jellyseerr** | A request management and media discovery tool for the Jellyfin/Plex ecosystem. |
| **Sonarr** | A PVR for Usenet and BitTorrent users that can monitor multiple RSS feeds for new episodes of your favorite shows. |
| **Radarr** | A movie collection manager for Usenet and BitTorrent users. |
| **Prowlarr** | An indexer manager/proxy built on the popular arr .net/reactjs base stack to integrate with your various PVR apps. |
| **qBittorrent** | A free and reliable P2P BitTorrent client. |
| **Gluetun** | A lightweight VPN client in a thin Docker container for your other Docker containers to use as a network gateway. |

### Homepage (`homepage/`)

| Service | Description |
| :--- | :--- |
| **Homepage** | A modern, fully static, fast, secure, and highly customizable application dashboard. |

### Immich (`immich/`)

| Service | Description |
| :--- | :--- |
| **Immich** | A self-hosted backup solution for photos and videos on mobile phones. |

### Pi-hole (`pihole/`)

| Service | Description |
| :--- | :--- |
| **Pi-hole** | A DNS sinkhole that protects your devices from unwanted content without installing any client-side software. |

### Nginx Proxy Manager (`npm/`)

| Service | Description |
| :--- | :--- |
| **Nginx Proxy Manager** | An easy-to-use, Docker-based reverse proxy management system. |

### Olivetin (`olivetin/`)

| Service | Description |
| :--- | :--- |
| **Olivetin** | A simple web-based tool for running pre-defined shell commands. |

## 🚀 Getting Started

### Prerequisites

  * Docker and Docker Compose installed on your server.
  * A user with `sudo` privileges to run Docker commands.
  * Git for cloning the repository.
  * A VPN subscription (this setup is configured for Mullvad with WireGuard, but can be adapted).

### Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/your-username/home-lab-setup.git
    cd home-lab-setup
    ```

2.  **Configure Environment Variables:**
    Each service stack that requires environment variables has a `.env.template` file. You need to copy these templates to `.env` and fill in the values.

      * **Media Stack:**

        ```bash
        cp media-stack/.env.template media-stack/.env
        nano media-stack/.env
        ```

        You will need to set your `TZ`, `PUID`, `PGID`, `DATA_PATH`, and VPN credentials.

      * **Homepage:**

        ```bash
        cp homepage/.env.template homepage/.env
        nano homepage/.env
        ```

        Fill in the API keys and credentials for the services you want to integrate with the dashboard widgets.

      * **Immich:**

        ```bash
        cp immich/.env.template immich/.env
        nano immich/.env
        ```

        Set the `UPLOAD_LOCATION`, `DB_DATA_LOCATION`, and database credentials.

      * **Pi-hole:**

        ```bash
        cp pihole/.env.template pihole/.env
        nano pihole/.env
        ```

        Set a `WEBPASSWORD` for the Pi-hole web interface.

3.  **Create External Docker Network:**
    This setup uses an external network `npm-net` for the reverse proxy to communicate with other services. Create it with the following command:

    ```bash
    docker network create npm-net
    ```

### Usage

This repository includes scripts to easily manage all the services.

  * **Start all services:**
    ```bash
    ./start-all.sh
    ```
  * **Stop all services:**
    ```bash
    ./stop-all.sh
    ```

You can also manage individual stacks by navigating to their directories and using `docker compose up -d` or `docker compose down`. The `media-stack` and `olivetin` directories also contain more granular scripts.

## ⚙️ Configuration

### Pi-hole

The Pi-hole configuration is managed in `pihole/etc-pihole/pihole.toml`. This setup includes several customizations:

  * **Custom DNS Records**: Local DNS records are defined in the `hosts` array to provide easy-to-remember domain names for services (e.g., `jellyfin.home.local`).
  * **Adlist**: A default adlist is included in `pihole/etc-pihole/adlists.list`.
  * **Listening Behavior**: The `listeningMode` is set to `ALL` to accept DNS queries from all interfaces. Ensure your firewall is configured correctly.

### Homepage

The Homepage dashboard is configured via YAML files in the `homepage/config/` directory:

  * **`services.yaml`**: Defines the service groups and the services within them, along with their icons, URLs, and widget configurations.
  * **`settings.yaml`**: Sets the title, theme, and layout of the dashboard.
  * **`widgets.yaml`**: Configures global widgets like resource monitoring (CPU, memory, disk), a search bar, and a datetime display.
  * **`bookmarks.yaml`**: Can be used to add bookmarks to the dashboard.

### Olivetin

The scripts available in Olivetin are defined in `olivetin/config/config.yaml`. This is a convenient way to start and stop parts of the media stack from a web UI.