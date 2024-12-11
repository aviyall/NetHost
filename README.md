# NetHost 🚀

NetHost is a lightweight networking tool that leverages [Serveo](https://serveo.net/), enabling you to expose local servers to the internet effortlessly, without requiring router or firewall configuration.

Whether you’re a developer looking for quick web hosting or a hobbyist needing secure SSH access, NetHost makes networking simple and effective.

## Key Features

- **Expose Local Services**: Seamlessly expose HTTP, TCP, and SSH traffic from your local network to the internet for development and testing.
- **Custom Web Hosting**: Host web pages online with a custom subdomain. NetHost ensures your website stays live by periodically sending requests.
- **Public SSH Server**: Expose a local SSH server securely, allowing remote connections from any network.
- **Network Flexibility**: Run NetHost on one device to expose services running on another within the same local network.

## Usage

```bash
Nethost <protocol> <hostname> <local_port> [subdomain/remote_port/alias]
```

### Positional Arguments

- `<protocol>` (REQUIRED):
  - Choose the type of tunnel:
    - `http`: Expose HTTP traffic.
    - `tcp`: Expose TCP traffic.
    - `ssh`: Expose SSH traffic.

- `<hostname>` (REQUIRED):
  - Specify the target host:
    - `lh`: Shortcut for localhost.
    - Public or local IP addresses or hostnames are also valid.
    - Ensure no firewall restrictions on port 22 on the host machine.

- `<local_port>` (REQUIRED):
  - Port on the host to forward traffic.
  - Recommended range: `1024–65535`.
  - For SSH, `22` is commonly used.

- `[subdomain/remote_port/alias]` (OPTIONAL):
  - For `http`: Specify a subdomain or leave blank for a random one.
  - For `tcp`: This field is treated as a remote port. If blank, a random port is assigned.
  - For `ssh`: This field is treated as an alias, This field is necessary.

## Examples

### HTTP Tunnels

#### Without Subdomain:
```bash
Nethost http lh 8080
```

#### With Subdomain:
```bash
Nethost http lh 8080 mysubdomain
```

#### With Specific Host IP:
```bash
Nethost http 192.168.1.24 8080 mysubdomain
```

### TCP Tunnels

#### Default Remote Port:
```bash
Nethost tcp lh 1234
```

#### Specific Remote Port:
```bash
Nethost tcp lh 1234 32545
```

### SSH Tunnels

#### On localhost:
```bash
Nethost ssh lh 22 myalias
```

#### On Specific Host:
```bash
Nethost ssh 192.168.35.21 22 myalias
```

## Special Notes

### HTTP Tunnel with Subdomain:
- Provides a custom URL for your web services: `https://<subdomain>.serveo.net`.

### TCP Tunnels:
- If the remote port is unspecified (`0`), Serveo assigns a random port.

### SSH Tunnels:
- An alias is mandatory, allowing connections like:
  ```bash
  ssh -J serveo.net user@myalias
  ```

## System Requirements

- Ensure `curl`, `ssh`, and `awk` are installed.
- For TCP tunnels, `ncat` (Netcat) is required.

## Error Handling

- **Network Issues**:
  - Automatically detects and waits for network reconnection, resuming tunnels afterward.
- **Serveo Downtime**:
  - Detects Serveo unavailability and retries until the service is back online.
- **Invalid Subdomain**:
  - Prompts an error if the chosen subdomain is unavailable.

## Advanced Functionality

- **Long-Term Hosting**: NetHost ensures reliability by sending periodic requests to keep the connection alive.
- **Multi-Device Support**: Use NetHost on one device to expose services hosted on another device in the same network.
