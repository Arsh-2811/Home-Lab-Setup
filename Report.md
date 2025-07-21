### **Project Report: Private Cloud Home Server Implementation**

* **Date of Report:** July 21, 2025
* **Objective:** To build a secure, reproducible, and private home server based on the "Private Cloud Blueprint," transforming a standard Ubuntu machine into a professional-grade personal cloud platform.

### **1. Executive Summary**

This project successfully implemented a multi-layered, secure home server architecture. The final system utilizes **Docker** for containerization, **Tailscale** for secure overlay networking, **Pi-hole** for network-wide DNS filtering, **Nginx Proxy Manager** as a reverse proxy, and **`mkcert`** for locally trusted SSL certificates. Key challenges involving DNS resolution, port conflicts, and mobile application connectivity were systematically diagnosed and resolved. The result is a robust, private cloud capable of securely hosting services like Immich, accessible via custom local domain names from authorized devices.

### **2. System Architecture & Guiding Principles**

The architecture was built on three core principles: **Security by Design**, **Reproducibility (Infrastructure as Code)**, and **Learning Through Understanding**. The final request flow for a service like Immich is as follows:

`Client Device -> Tailscale Network -> Pi-hole (DNS Resolution) -> Nginx Proxy Manager (Reverse Proxy & SSL) -> Docker Network -> Immich Container`

### **3. Phase 1: Foundation - Initial Server Hardening**

This foundational phase established a secure baseline for the server and proceeded without issues.

* **System Update:** The Ubuntu system was fully updated and upgraded to patch any initial vulnerabilities (`sudo apt update && sudo apt full-upgrade -y`).
* **Non-Root User:** A non-root administrative user (`arsh-sharan`) was created and granted `sudo` privileges. The root account was subsequently unused for daily operations.
* **SSH Hardening:** Remote access was secured by disabling direct root login and password-based authentication. Access is exclusively handled via ED25519 SSH key pairs.
* **Firewall Configuration:** The Uncomplicated Firewall (UFW) was configured with a default-deny incoming policy, explicitly allowing only OpenSSH traffic.

### **4. Phase 2: Core Services Deployment & Troubleshooting**

This phase involved installing the main infrastructure components and presented the first set of technical challenges.

#### **4.1 Docker and Tailscale Integration**
* Docker Engine and Docker Compose were installed from Docker’s official repository.
* The `arsh-sharan` user was added to the `docker` group for non-root management.
* Tailscale was installed and configured, successfully connecting the server to the private tailnet and receiving a stable `100.x.y.z` IP address. Key expiry was disabled for the server to ensure continuous connectivity.

#### **4.2 Pi-hole Deployment & DNS Troubleshooting**
* Pi-hole was deployed as a Docker container. The initial configuration used `network_mode: "host"` to allow Pi-hole to bind to port 53 for DNS services.
* **Problem #1: Asymmetrical Ad-Blocking.** Ad-blocking was effective on remote clients (Mac) connected via Tailscale but failed on the Ubuntu host machine itself.
* **Diagnosis & Resolution #1:** The `resolvectl status` command failed, confirming that the `systemd-resolved` service had been successfully disabled as per the blueprint's instructions to free up port 53. This indicated the host had reverted to using `/etc/resolv.conf`. The issue was that this file did not point to the local Pi-hole instance.
    * **Solution:** The `/etc/resolv.conf` file was edited to contain a single line: `nameserver 127.0.0.1`. This forced the host OS to direct all its DNS queries to the Pi-hole service running locally, resolving the issue.

#### **4.3 Nginx Proxy Manager (NPM) & Port Conflict Resolution**
* A dedicated external Docker network, `npm-net`, was created to facilitate secure communication between the proxy and future application containers.
* **Problem #2: NPM Container Start-up Failure.** The `docker compose up -d` command for NPM failed with an `address already in use` error for port 80.
* **Diagnosis & Resolution #2:** Using the `sudo lsof -i :80` command, the process occupying port 80 was identified as `pihole-FTL`. The `network_mode: "host"` setting in Pi-hole's configuration caused its internal web server to bind to the host's port 80, creating a direct conflict.
    * **Solution:** The Pi-hole `docker-compose.yml` was modified. `network_mode: "host"` was removed. Instead, ports were explicitly mapped: `53:53/tcp`, `53:53/udp` for DNS, and `8080:80/tcp` for the web admin interface. This freed port 80 on the host, allowing the NPM container to start successfully.

### **5. Phase 3: Application Deployment & Service Integration (Immich)**

This phase focused on deploying the first application and integrating it into the existing infrastructure.

#### **5.1 Immich Deployment & Reverse Proxy Configuration**
* Immich was deployed from its official `docker-compose.yml`. The configuration was modified to connect the `immich-server` service to the external `npm-net` network. The service's default port mapping was removed to ensure it was only accessible via the reverse proxy.
* A Local DNS record was created in Pi-hole to map `immich.home.local` to the server's Tailscale IP.
* A proxy host was created in NPM for `immich.home.local`.
* **Problem #3: `502 Bad Gateway` Error.** Accessing the domain resulted in a 502 error from NPM.
* **Diagnosis & Resolution #3:** A systematic check confirmed containers were healthy and network attachment was correct. A detailed review of the `docker ps` output revealed the critical clue: the `immich-server` container's internal port was `2283`, not `3001` as assumed. NPM was trying to forward traffic to the wrong port.
    * **Solution:** The `Forward Port` in the NPM proxy host settings for `immich.home.local` was changed from `3001` to `2283`, immediately resolving the 502 error.

### **6. Phase 4: Secure Access (HTTPS) & Mobile Connectivity**

This final phase involved securing the connection and tackling the most complex challenge of the project.

#### **6.1 `mkcert` Implementation for Custom Domains**
* The initial approach using Tailscale-issued certificates worked for browsers but failed for the native mobile app due to strict SSL validation rules. The user opted for the `mkcert` method to maintain the custom `immich.home.local` domain.
* `mkcert` was installed on the server, a private Certificate Authority (CA) was created, and a wildcard certificate for `*.home.local` was generated.
* The `rootCA.pem` file was successfully installed on the client devices (macOS, Android, iPad) by following platform-specific procedures, teaching them to trust the private CA.
* NPM was configured with a new custom certificate, successfully providing trusted `https` access to `immich.home.local` from web browsers on all configured devices.

#### **6.2 Final Android App Connectivity Challenge**
* **Problem #4: Persistent Mobile App Failure.** Despite disabling Private DNS and installing the `mkcert` root CA, the native Immich app on Android still failed to connect with a "Server is not reachable" error.
* **Diagnosis & Resolution #4:** Research and analysis concluded this is a hard limitation of the app's security policy. The native app's networking library is hardcoded to *only* trust public, built-in CAs and ignores any user-added CAs (`mkcert` included) as a security measure.
    * **Solution:** As using the MagicDNS name was declined, the chosen workaround was to provide a plain `http` endpoint exclusively for the mobile app. A new DNS record (`immich-app.home.local`) was created in Pi-hole. A corresponding new proxy host was created in NPM with SSL explicitly set to **None**. Using the URL `http://immich-app.home.local` in the Immich app worked perfectly.

### **7. Conclusion & Final State**

The project concluded with a fully operational private cloud that successfully meets all initial requirements while providing valuable lessons in network and security troubleshooting.

**Final Configuration:**
* **Browser Access:** Securely accessed via `https://immich.home.local` with a trusted `mkcert` SSL certificate.
* **Mobile App Access:** Functionally accessed via `http://immich-app.home.local` over the encrypted Tailscale network as a necessary workaround for the app's security policies.

This comprehensive setup provides a powerful, private, and expandable foundation for future self-hosting endeavors.
