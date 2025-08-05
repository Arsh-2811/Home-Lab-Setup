# Mesh VPNs and Tailscale Explained

Welcome to your comprehensive guide to understanding Mesh VPNs, with a special focus on how Tailscale works. We will start from the absolute basics of how computer networks function and build our way up, step-by-step, to the sophisticated technology that powers modern secure networks.

-----

## Part 1: The Building Blocks - Core Networking Fundamentals

To understand a VPN, we first need to understand the language of the internet.

### 🧠 Core Networking Fundamentals

#### 1\. IP Addressing

Think of an IP (Internet Protocol) address as a device's mailing address on a network. It's a unique identifier that allows data to be sent to and from the correct destination.

* **IPv4 & IPv6:**
  * **IPv4:** The older standard, e.g., `192.168.1.101`. It uses a 32-bit address, providing approximately 4.3 billion unique addresses. We have largely run out of these.
  * **IPv6:** The new standard, designed to solve the shortage of IPv4 addresses. It uses a 128-bit address, e.g., `2001:0db8:85a3:0000:0000:8a2e:0370:7334`. The number of available IPv6 addresses is practically limitless.
* **Public vs. Private IP addresses:**
  * **Public IP:** This is the address your entire home or office network uses to communicate with the outside internet. It's assigned by your Internet Service Provider (ISP) and is globally unique.
  * **Private IP:** This is the address your device (laptop, phone, etc.) uses *within* your local home or office network. These addresses are not unique globally and are reused in millions of homes. Common private ranges are `192.168.x.x`, `10.x.x.x`, and `172.16.x.x` to `172.31.x.x`.
* **CIDR Notation and Subnetting:**
  * CIDR (Classless Inter-Domain Routing) is a shorthand for defining a range of IP addresses. For example, `192.168.1.0/24` describes a network.
  * `192.168.1.0` is the starting address of the network.
  * `/24` is the subnet mask. It specifies that the first 24 bits of the address identify the network itself, leaving the remaining 8 bits to identify individual devices. This `/24` network can have 254 usable addresses (from `192.168.1.1` to `192.168.1.254`).
* **Special IP Addresses:**
  * **Loopback Address:** Typically `127.0.0.1` (or `::1` in IPv6). It means "this computer." When a device sends data to this address, it's talking to itself. It's used for testing and running local services.
  * **Broadcast Address:** The last address in a subnet (e.g., `192.168.1.255` in a `/24` network). Data sent here goes to *every* device on the local network.
  * **Reserved IPs:** Certain IP ranges are reserved for specific purposes (like private networks) and cannot be used on the public internet.

#### 2\. MAC Addressing and ARP

* **MAC Addresses:**
  * A MAC (Media Access Control) address is a unique, permanent hardware identifier baked into your device's network card by the manufacturer. It looks like `00:1A:2B:3C:4D:5E`.
  * **Analogy:** If an IP address is like your home's mailing address (which can change if you move), a MAC address is like your body's fingerprint (which is permanent).
  * MAC addresses are used for communication *within* a local network (LAN).

* **ARP (Address Resolution Protocol):**

  * ARP is the glue between IP and MAC addresses on a local network.
  * **How it works:** When your computer wants to send data to another device on the same local network (e.g., `192.168.1.5`), it knows the IP address but not the hardware MAC address. It shouts out an ARP request to the entire local network: "Who has the IP address `192.168.1.5`? Please tell me your MAC address."
  * The device with that IP address replies with its MAC address. Your computer then stores this mapping in its "ARP cache" for future use and sends the data.

#### 3\. Routing Basics

Routing is the process of choosing a path for data packets to travel from a source to a destination across different networks.

* **Default Gateway:**
  * This is the IP address of your router on your local network (e.g., `192.168.1.1`).
  * When your computer needs to send data to an IP address *outside* your local network (like `google.com`), it doesn't know how to get there directly. So, it sends the packet to the default gateway (your router), trusting that the router knows how to forward it towards the internet.
* **Routing Tables:**
  * Every computer and router has a routing table, which is a set of rules, like a simple map. It tells the device where to send a packet based on its destination IP address.
  * A simple computer's routing table might look like this:
      1. **Destination:** `192.168.1.0/24` (my local network) -\> **Action:** Send directly on the local network.
      2. **Destination:** `0.0.0.0/0` (everywhere else) -\> **Action:** Send to the default gateway (`192.168.1.1`).
* **Static vs. Dynamic Routing:**
  * **Static:** An administrator manually programs all the routes into the routing table. It's simple and secure for small, unchanging networks but impossible to manage for large, complex ones.
  * **Dynamic:** Routers talk to each other using special protocols (like OSPF or BGP) to automatically discover routes and update their routing tables when the network changes (e.g., a link goes down). This is how the global internet works.

#### 4\. NAT (Network Address Translation)

NAT is the technology that allows the multiple devices in your home (with private IPs) to share a single public IP address provided by your ISP. Your home router performs NAT.

* **How it Works (PAT - Port Address Translation):**

    1. Your laptop (`192.168.1.101`) wants to connect to `google.com`. It sends a packet from a random source port, say `51000`, to `google.com`'s port `443` (HTTPS).
    2. Your router receives this packet. It translates the *source* private IP (`192.168.1.101`) to your public IP (e.g., `203.0.113.10`).
    3. Crucially, it records this translation in a table: `(Internal IP:Port) 192.168.1.101:51000` -\> `(External IP:Port) 203.0.113.10:51000`.
    4. When Google replies to `203.0.113.10` on port `51000`, your router looks at its table, sees that this traffic belongs to your laptop, and forwards the packet to `192.168.1.101`.

* ### **Source NAT (SNAT)**

  #### What SNAT does

  **Changes the source IP address** of a packet as it leaves your network.

  #### Easy SNAT example

  Imagine you're at home, and your phone (with internal IP `192.168.1.10`) wants to visit Google. Your home router will:

  * Change the **source IP** from `192.168.1.10` to your router's **public IP** (e.g., `203.0.113.5`)
  * Send the packet to Google.

  Google sees the packet as coming from `203.0.113.5`, not your internal phone IP.

  #### Why SNAT's used

  * To **hide internal IP addresses**.
  * To **share one public IP** across multiple internal devices.

* ### **Destination NAT (DNAT)**
  
  #### What DNAT does
  
  **Changes the destination IP address** of a packet as it comes into your network.

  #### Easy DNAT example

  Let’s say you’re hosting a web server at home on `192.168.1.100`, and someone on the internet tries to access your public IP `203.0.113.5`.

  Your router does DNAT:

  * It sees a request to `203.0.113.5:80` (web port).
  * It **changes the destination IP** to `192.168.1.100`.
  * It forwards the request to your internal server.

  #### Why DNAT's used

  * To **allow access to internal services** from outside.
  * Often called **port forwarding**.

* ### **CGNAT (Carrier-Grade NAT):**

  * Because ISPs are also running out of public IPv4 addresses, they often do the same thing your home router does, but on a massive scale.
  * They assign a *private* IP address (e.g., from the `100.64.0.0/10` range) to your entire home network. Your router then connects to the ISP's network, where another giant router performs NAT again, sharing one public IP among hundreds or thousands of customers.
  * This is called **Double NAT**. It breaks things like port forwarding, online gaming, and hosting services because there's no way to tell the ISP's giant router to forward a specific port just to you. This is a critical problem that mesh VPNs are designed to solve.

-----

## Part 2: Securing the Connection - Tunnels and Encryption

Now that we understand how networks talk, let's see how we can make their conversations private and secure.

### 🔒 Network Security and Tunneling Concepts

#### 5\. Firewalls and Ports

* **Port Numbers:** If an IP address is the building's street address, a port number is the specific apartment number. It allows a single device to handle many different types of network conversations simultaneously.

  * **Examples:**
    * Port `80`: HTTP (unsecured web traffic)
    * Port `443`: HTTPS (secured web traffic)
    * Port `22`: SSH (secure remote terminal access)
    * Port `25`: SMTP (email sending)

* **Firewalls:** A firewall is a security guard for a network. It inspects incoming and outgoing traffic and decides whether to allow or block it based on a set of rules.

  * **Inbound Rules:** Control traffic *coming into* your network or device. For example, "Block all incoming connections except for port `443`." This prevents hackers from trying to access random services on your computer.
  * **Outbound Rules:** Control traffic *leaving* your network or device. For example, a corporate firewall might say, "Block all outgoing traffic except for standard web Browse on ports `80` and `443`."

* **How Firewalls Affect VPNs:** Firewalls can block the specific ports that VPNs use to communicate. A key challenge for any VPN is to get its traffic through firewalls, which is why many are designed to use common ports like `443` to disguise their traffic as normal web traffic.

#### 6\. Encryption Basics

Encryption scrambles data so that only authorized parties can read it.

* **Symmetric Encryption:**

  * Uses a **single, shared secret key** to both encrypt and decrypt data.
  * **Analogy:** A locked box where the same key is used to both lock and unlock it. You and your friend must have identical copies of the key.
  * **Pros:** Very fast.
  * **Cons:** Securely sharing the secret key in the first place is a major challenge.
  * **Example:** AES (Advanced Encryption Standard).

* **Asymmetric Encryption (Public-Key Cryptography):**

  * Uses a **pair of keys**: a `public key` and a `private key`.
  * The `public key` can be shared with anyone. It's used to *encrypt* data.
  * The `private key` must be kept secret. It's the only key that can *decrypt* data encrypted by its corresponding public key.
  * **Analogy:** A public mailbox. Anyone can drop a letter in (encrypt with the public key), but only you have the key to open the mailbox and read the letters (decrypt with the private key).
  * **Pros:** Solves the key-sharing problem. Also used for digital signatures to verify identity.
  * **Cons:** Much slower than symmetric encryption.
  * **Example:** RSA.

* **TLS/SSL vs. VPN Encryption:**

  * Both use a hybrid approach: they use slow *asymmetric* encryption to securely exchange a fast *symmetric* key at the beginning of a session. Then, they use that symmetric key to encrypt the actual bulk data transfer.

  * **TLS/SSL (Transport Layer Security):**
    * Secures traffic for a specific *application*, like your web browser (e.g., HTTPS).
    * Encrypts **only the data of that specific app** — such as your login, messages, or payment info on a website.
    * It **does not hide** which website you're connecting to — your ISP can still see domain names (like `example.com`).
    * Used commonly in web browsers, email clients, and messaging apps.

  * **VPN Encryption (IPSec, WireGuard):**
    * Secures traffic at the **network level**, not just for one app.
    * It creates a **secure encrypted tunnel** between your device and a VPN server — this tunnel hides **all your traffic**, including which websites or services you're accessing.
    * **Tunnel:** A private, encrypted path through the public internet. All data is wrapped in encryption as it travels to the VPN server.
    * **VPN Server:** A remote computer that decrypts your traffic and forwards it to its destination on the internet. It acts as a trusted relay.
    * Your ISP (or anyone on the same Wi-Fi) can only see you're connected to the VPN — they **cannot see what you're doing online** or where your traffic is headed.
    * Commonly used to protect privacy, avoid surveillance, bypass censorship, or access region-restricted content.

    * **Summary Table:**

      | Feature | TLS/SSL | VPN |
      |--------|---------|-----|
      | **Protects** | One app’s traffic (e.g., browser) | All traffic from device |
      | **Hides data content** | ✅ Yes | ✅ Yes |
      | **Hides destination (e.g., website name)** | ❌ No | ✅ Yes |
      | **Encrypts everything from device** | ❌ No | ✅ Yes |
      | **Encryption type** | Hybrid (asymmetric + symmetric) | Hybrid (asymmetric + symmetric) |

-----

## Part 3: From Traditional to Modern - VPN Architectures

### 🌐 VPN and Mesh Networking Specific Concepts

#### 7\. Traditional VPNs (Client-Server Model)

Most consumer and corporate VPNs follow a "hub-and-spoke" or client-server model.

* **How it Works:**
    1. You install a VPN client on your laptop.
    2. The client establishes a single, encrypted tunnel to a central VPN server located somewhere else in the world.
    3. *All* your internet traffic is routed through this server.
    4. The server then decrypts your traffic and sends it to its final destination on the public internet. Your traffic appears to come from the VPN server's IP address.
* **Pros:** Simple concept, good for hiding your IP address from public websites.
* **Cons:**
  * **Single Point of Failure:** If the server goes down, your connection is lost.
  * **Bottleneck:** All traffic must go through the central server, even if you are talking to a device in the same room. This adds latency and slows things down.
  * **Centralized Trust:** You must completely trust the VPN provider not to log or inspect your traffic.

#### 8\. Mesh VPNs (Peer-to-Peer Model)

Mesh VPNs, like Tailscale, create a flat, secure network where every device can talk to every other device directly.

* **How it Works:**
  * Instead of routing all traffic through a central server, devices establish direct, encrypted, peer-to-peer (P2P) tunnels with each other as needed.
  * If your laptop in New York wants to connect to your file server in London, it creates a direct tunnel to London. Traffic doesn't need to be relayed through a server in Chicago first.
* **The Role of a "Coordination Server":** A central server is still needed, but its role is completely different. It **does not handle your traffic**. It's a "coordination server" or "control plane" that acts like an introduction service. It helps devices find each other, exchange public keys, and manage access rules. Your actual data (the "data plane") flows directly between your devices.
* **Pros:**
  * **Low Latency:** Direct connections are much faster.
  * **Resilience:** No single point of failure for your data traffic.
  * **Efficiency:** Traffic only goes where it needs to.

#### 9\. WireGuard (The Heart of Modern VPNs)

WireGuard is a modern, high-performance VPN protocol that forms the core of Tailscale.

* **Key Features:**

  * **Simplicity:** It has a very small codebase (around 4,000 lines of code), making it easy to audit and less likely to have security vulnerabilities compared to older protocols like OpenVPN or IPSec (which have hundreds of thousands of lines).
  * **High Performance:** It's significantly faster and uses less battery than older protocols.
  * **Strong Cryptography:** It uses modern, state-of-the-art cryptographic primitives.

* **How it Works with Public Keys:**

    1. Every device in a WireGuard network has its own private key (kept secret) and a corresponding public key (shared with others).
    2. To create a secure tunnel between two devices ("peers"), you simply tell Peer A the public key of Peer B, and vice-versa.
    3. WireGuard handles the authentication and encryption automatically using these keys. There are no complex certificates or credentials to manage.

* **`AllowedIPs`:** This is a crucial setting in a WireGuard configuration. It tells a device which IP addresses are reachable through the tunnel with a specific peer. For example, if you set `AllowedIPs = 10.0.0.5/32` for a peer, your device knows that to reach the IP address `10.0.0.5`, it must send the traffic through the encrypted WireGuard tunnel to that peer. Tailscale manages these `AllowedIPs` rules for you automatically.

-----

## Part 4: Overcoming Modern Hurdles – CGNAT and NAT Traversal

One of the biggest challenges in building peer-to-peer (P2P) mesh VPNs is enabling two devices to connect directly when **both are hidden behind NAT or CGNAT**. This is where **NAT traversal** comes in — a clever set of techniques that make direct communication possible.

### 🌍 CGNAT and NAT Traversal

#### 10. CGNAT Challenges

Most devices connected to the internet today are **not directly reachable** because they sit behind a **NAT (Network Address Translation)** router, which uses a single public IP for many devices. When your **ISP** also applies NAT at their end, this becomes **Carrier-Grade NAT (CGNAT)**.

In this case:

* Your device doesn’t even get a public IP address.
* The ISP’s NAT blocks **all incoming connections**.
* Two devices (say your laptop at home and a file server at the office) **can’t initiate connections to each other**.

📞 **Analogy:**  
It’s like trying to call someone when **neither of you has a phone number** — you can dial out, but no one can dial in.

This is the exact problem that modern VPNs like **Tailscale** are designed to solve — by using **NAT traversal techniques**.

#### 11. NAT Traversal Techniques

**NAT traversal** is a toolkit of networking tricks that lets two devices establish a direct, secure connection — even when both are behind NATs or CGNAT.

### 🔍 STUN (Session Traversal Utilities for NAT)

* **Purpose:** To figure out your device’s **public-facing IP and port**.
* **How it works:**
  1. Your device sends a message to a **public STUN server** on the internet.
  2. The server replies:  
     > "I received your message from `203.0.113.10:51000`."
  3. Your device now knows:  
     > “This is how I appear to the outside world.”

This information is shared with other peers via the **coordination server** (e.g. Tailscale’s control plane).

### 🕳️ Hole Punching

Once both peers know each other’s public IP and port (via STUN + coordination server), they try to **connect to each other at the same time**:

1. **Peer A** sends a packet to **Peer B’s** public IP:port.
2. **Peer B** simultaneously sends a packet to **Peer A’s** public IP:port.
3. Each router sees the outgoing request and adds a **temporary NAT rule**:  
   > “Allow traffic from that destination to return.”

🎉 If both NATs are cooperative, the “holes” line up, and a **direct, encrypted P2P tunnel** is established.

### 🔒 What if Hole Punching Fails?

Sometimes, routers are **too strict** — especially with **Symmetric NAT**, which:

* Creates a **new NAT mapping per destination**.
* Accepts replies **only from the exact destination IP and port**.
* ❌ Makes hole punching almost impossible.

### 🔁 TURN / DERP (Fallback Relays)

When hole punching doesn’t work, VPNs like Tailscale fall back to **relay servers**.

* **TURN** (Traversal Using Relays around NAT) and **DERP** (used by Tailscale) are **cloud-based relay servers**.
* Both peers connect to the DERP server instead of directly to each other.
* The DERP server forwards **encrypted traffic** between them.

🔐 **Important:**  
The DERP server **cannot decrypt** or see your data — it simply relays encrypted **WireGuard packets**. This ensures:

* **Privacy remains intact**
* **Connectivity always works**, no matter how restrictive the network

✅ **Bonus:** Tailscale has **a global network of DERP servers**, automatically choosing the nearest one for the best performance.

### 📦 Quick Summary Table

| Technique        | Purpose                                 | Role in NAT Traversal                     |
|------------------|------------------------------------------|--------------------------------------------|
| **STUN**         | Discover your public IP and port         | Enables devices to know how they appear to the internet |
| **Hole Punching**| Create a direct connection through NAT   | Tries to open return paths in both routers |
| **TURN/DERP**    | Relay encrypted traffic if all else fails| Ensures connection even through strict NAT |

### 🚨 Symmetric NAT: The Trouble-Maker

Symmetric NAT is a type of NAT that:

* Assigns **a new external port for each unique destination**
* **Doesn’t reuse ports** or allow flexible return paths
* Makes it nearly impossible for P2P hole punching to work

👎 This is common in **mobile networks, corporate networks**, and ISPs using **CGNAT**.

✅ Browsing still works fine — because your browser always starts the conversation (outbound request).  
❌ Peer-to-peer traffic struggles — because both peers try to start conversations, and symmetric NATs **block unknown incoming packets**.

### 🧠 Final Thoughts

NAT traversal is **one of the biggest technical challenges** in building secure, fast, direct mesh VPNs. Tools like Tailscale make it seamless by:

* Trying **hole punching first** (for speed)
* Falling back to **DERP relays** (for reliability)
* Hiding all complexity behind an easy-to-use interface

The result?  
🟢 Your devices can always connect securely — even if they’re both behind strict CGNAT.

-----

## Part 5: How Tailscale Works - A Step-by-Step Guide

Now, let's put everything we've learned together to understand what happens when you use Tailscale.

**The Goal:** Connect your laptop to your home server as if they were on the same network, securely, from anywhere in the world.

1. **Sign-in and Key Generation:**

      * You install the Tailscale client on your laptop and your server.
      * You sign in to both using a third-party Identity Provider (like a Google or Microsoft account). You are not creating a new password for Tailscale.
      * On first login, the Tailscale client on each device generates a unique private key (which it saves securely on the device) and a corresponding public key.

2. **Registering with the Coordination Server:**

      * The client on your laptop sends its public key to Tailscale's central **Coordination Server**.
      * The Coordination Server checks your identity with Google/Microsoft and adds this new device (and its public key) to your private network account. It also assigns it a unique, stable private IP address in the `100.x.x.x` range.
      * You repeat this process for your home server. Now, the Coordination Server knows about two devices in your network, their public keys, and their Tailscale IPs.

3. **Connecting to a Peer:**

      * On your laptop, you try to access your server using its Tailscale IP (e.g., `ping 100.101.102.103`).
      * The Tailscale client on your laptop asks the Coordination Server: "I want to talk to `100.101.102.103`. What's its public key and how can I reach it?"

4. **The "Introduction" and NAT Traversal:**

      * The Coordination Server replies to your laptop: "That's your home server. Here is its public key. I last saw it at this public IP and port: `[Server's Public IP:Port]`."
      * Simultaneously, the Coordination Server sends a message to your home server: "Your laptop wants to talk to you. Here is its public key. It's at `[Laptop's Public IP:Port]`."
      * Now, both devices have the information they need. They immediately start the **hole punching** process described earlier, sending encrypted WireGuard packets to each other's public IP and port.

5. **Connection Established\!**

      * **Best Case (Direct Connection):** Hole punching succeeds\! A direct, secure, peer-to-peer WireGuard tunnel is established between your laptop and your server. The Coordination Server is no longer involved. This is the fastest and most common outcome.
      * **Fallback Case (Relayed Connection):** If hole punching fails, both clients will automatically pivot and connect to the nearest **DERP server**. They then pass their encrypted WireGuard traffic through the relay. The connection still works, it's just a bit slower. Tailscale's client constantly re-evaluates the path and will switch to a direct connection if one becomes available later.

-----

## Part 6: Advanced Concepts and the Broader Landscape

### 📦 Advanced Networking (Optional but Very Useful)

#### 12\. DNS and Tailscale's MagicDNS

* **DNS (Domain Name System):** The internet's phonebook. It translates human-friendly domain names (like `www.google.com`) into computer-friendly IP addresses (like `142.250.196.68`).
* **MagicDNS:** Remembering IP addresses like `100.101.102.103` is hard. MagicDNS is Tailscale's integrated DNS service. It automatically registers a human-friendly name for each device you add to your network (e.g., `my-laptop`, `home-server`). Now you can just type `ping home-server` from your laptop, and MagicDNS will automatically resolve it to the correct Tailscale IP address. It just works.

#### 13\. Comparison to Other Mesh VPNs

Tailscale is not the only player in this space. Here's a quick comparison with two other popular solutions:

* **Tailscale:**

  * **Philosophy:** Simplicity and "it just works."
  * **Technology:** Built on WireGuard. Uses a centralized (but trusted) coordination server for easy setup and key management.
  * **Best for:** Individuals, small teams, and anyone who values ease of use and high performance without complex configuration.

* **ZeroTier:**

  * **Philosophy:** Maximum flexibility and decentralization.
  * **Technology:** Uses its own custom protocol, not WireGuard. Acts like a global, virtual Layer 2 network switch, which is more powerful but also more complex than Tailscale's Layer 3 routing.
  * **Best for:** Users who need advanced networking features (like bridging local LANs) and want more control, including the ability to self-host their own control plane ("root servers").

* **Nebula:**

  * **Philosophy:** Security and scalability, born at Slack.
  * **Technology:** A new protocol inspired by Tinc. It relies heavily on a self-hosted Public Key Infrastructure (PKI) using "lighthouses" for discovery.
  * **Best for:** Large organizations with the technical expertise to manage their own certificate authorities and infrastructure. It's designed to be self-hosted and is less of a "turnkey" solution than Tailscale or ZeroTier.

#### 14\. Network Interface Concepts

* **TUN/TAP Interfaces:**
  * When you run a VPN client, it creates a new, virtual network interface on your computer. You can see it if you type `ifconfig` or `ip addr`.
  * **TUN (Tunnel Interface):** A virtual Layer 3 (IP-level) network device. When an application sends a packet to the TUN interface, the VPN software grabs it, encrypts it, and sends it out over the physical network. This is what Tailscale and most modern VPNs use.
  * **TAP (Network Tap):** A virtual Layer 2 (Ethernet-level) network device. It's more powerful as it can transport non-IP traffic, but also more complex and less efficient. This is what ZeroTier behaves like.

-----

### Conclusion

A **Mesh VPN** like Tailscale represents a fundamental shift away from the traditional, centralized VPN model. By leveraging the power of modern cryptography (WireGuard), clever NAT traversal techniques (STUN/Hole Punching), and a smart coordination plane, it creates a secure, private network that is:

* **Fast:** By favoring direct peer-to-peer connections.
* **Simple:** By automating key exchange, IP assignment, and DNS.
* **Resilient:** By having a reliable relay (DERP) fallback.
* **Secure:** By building on a small, auditable, and encrypted-by-default foundation.

You now have a complete picture, from the basic bits and bytes of IP addressing all the way to the complex dance of NAT traversal that makes your private, global network a reality.
