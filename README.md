##  **UNDER DEVELOPMENT 🧑‍🏭**
# NetHost

**NetHost** is a lightweight networking tool that leverages [Serveo](https://serveo.net), an online platform providing reverse SSH tunneling.

With NetHost, you can expose a local server from your own computer or network to the internet without any router or firewall configurations.

This tool is ideal for developers and hobbyists who want a simple way to make local services publicly accessible.

## Features
- **Expose Local Services**  
  Easily expose HTTP, TCP, and SSH traffic from your local network to the internet, making development and testing more convenient.
- **Dedicated Web Hosting**  
  NetHost allows you to host webpages on the internet for free with custom domain names. It also helps keep your website alive by sending periodic requests, making it an ideal solution for long-lasting web hosting.
- **SSH Server**
  A key feature of NetHost is its ability to expose a local SSH server to the public, enabling users to securely connect to the SSH server from any network.
- **Expose Local Server from Any Device on the Same Network**  
  The server does not need to be the device running NetHost. NetHost can operate on another device within the same network and still function normally, allowing you to expose local services seamlessly. 

## Usage

```shell
./script_name.sh <protocol> <hostname> <Localport> [subdomain]
```
- **Protocols** (REQUIRED)
  - Specify the type of tunnel to create.
  - There are three options available [ __http__ , __tcp__ , __ssh__ ].
  - `http` > HTTP tunnel.
  - `tcp` > TCP tunnel.
  - `ssh` > SSH tunnel.
- **Hostname** (REQUIRED)
  - This Field can either be **local or public** ip address or hostname.
  - __Ensure that there are no firewall restrictions for ssh port(22) on the host.__
  - `lh` (shortcut for `localhost`)
- **LocalPort** (REQUIRED)
  - Port number should be between 1024–65535 is recommended
  - For `ssh` keeping it in 22 is recommended
- **Subdomain** (OPTIONAL)
  - For `http` subdomain is optional
  - For `tcp` there is nothing as subdomain
  - For `ssh` subdomain is a REQUIRED field
- **Exceptional Case in `tcp`**
  - For `tcp` the 4th parameter termed as subdomain is configured as Remoteport.
  - This field can be kept empty then default value 0 will be used
  - 0 will assgin a random available portnumber
- **Examples**
  - **HTTP TUNNEL WITHOUT SUBDOMAIN ON LOCALHOST**
    - ```ps
      NetHost http lh 8080
      ```
  - **HTTP TUNNEL WITH SUBDOMAIN ON LOCALHOST**
    - ```ps
      NetHost http lh 8080 mysubdomain
      ```
  - **HTTP TUNNEL WITH SUBDOMAIN ON AN IP ADR**
    - ```ps
      NetHost http 192.168.1.24 8080 mysubdomain
      ```
  - **HTTP TUNNEL WITHOUT SUBDOMAIN ON LOCALHOST**
    - ```ps
      NetHost http lh 8080
      ```
  - **TCP TUNNEL ON LOCALHOST**
    - ```ps
      NetHost tcp lh 1234
      ```
  - **TCP TUNNEL ON LOCALHOST WITH REMOTEPORT**
    - ```ps
      NetHost tcp lh 1234 32545
      ```
  - **SSH TUNNEL ON LOCALHOST**
    - ```ps
      NetHost ssh lh 22 mysubdomain
      ```
  - **SSH TUNNEL ON IP ADR**
    - ```ps
      NetHost ssh 192.168.35.21 22 mysubdomain
      ```


---
