# NetHost       ![status](https://img.shields.io/uptimerobot/status/m798198859-ecf1064c616a7c3cbfac9734)

NetHost is a lightweight networking tool that leverages [Serveo](https://serveo.net/), enabling you to expose local servers to the internet effortlessly, without requiring router or firewall configuration.

Whether you’re a developer looking for quick web hosting or a hobbyist needing secure SSH access, NetHost makes networking simple and effective.
 
## Key Features

- **Expose Local Services**: Seamlessly expose HTTP, TCP, and SSH traffic from your local network to the internet for development and testing.
- **Custom Web Hosting**: Host web pages online with a custom subdomain. NetHost ensures your website stays live by periodically sending requests.
- **Public SSH Server**: Expose a local SSH server securely, allowing remote connections from any network.
- **Network Flexibility**: Run NetHost on one device to expose services running on another within the same local network.

## Steps to Install

1. **Download the `.deb` File**

   First, download the `nethost_v*.*.*.deb` file from the GitHub repository.
   Or just use this wget command
   - ```bash
     wget https://github.com/aviyall/NetHost/raw/refs/heads/main/nethost_v1.2.0.deb   
     ```

3. **Install the Package**

   Open a terminal and navigate to the directory where the `.deb` file is located. Then, run the following command:

   ```bash
   sudo dpkg -i nethost_v1.0.1.deb && sudo apt-get install -f
   ```
## Usage

```bash
Usage: nhost [OPTIONS]

Options:
  -o,  --option       'http' or 'tcp' or 'ssh' 
  -h,  --hostname     Specify the hostname
  -lp, --local-port   Set the local port number
  -rp, --remote-port  Set the remote port number
  -s,  --subdomain    Coustom subdomain of http tunnel
  -a,  --alias        Assign an alias for ssh

  -H,  --help         Show this help message 
```


## Examples

### HTTP Tunnels

#### Without Subdomain:
```bash
nhost -o http -h hostname -lp 8080
or
serveo -o http -h hostname -lp 8080
```

#### With Subdomain:
```bash
nhost -o http -h hostname -lp 8080 -s mysubdomain
or
serveo -o http -h hoatname -lp 8080 -s mysubdomain
```

### TCP Tunnels

#### Default Remote Port:
```bash
nhost -o tcp -h hostname -lp 1234  #set --remote-port empty or 0 for random remote port
or
serveo -o tcp -h hostname -lp 1234
```

#### Specific Remote Port:
```bash
nhost -o tcp -h hostname -lp 1234 -rp 32545
or
serveo -o tcp -h hostname -lp 1234 -rp 32545
```

### SSH tunnel

#### THIS EXPOSES YOUR LOCAL SSH SERVER TO THE PUBLIC
```bash
nhost -o ssh -h hostname -a myalias #leave --local-port(-lp) empty or 22
or 
serveo -o ssh -h hostname -a myalias
```
#### connect to ssh server with : `ssh -J serveo.net user@myalias`


## Special Notes

### HTTP Tunnel with Subdomain:
- Provides a custom URL for your web services: `https://<subdomain>.serveo.net`.

### TCP Tunnels:
- Recommended range for local port : `1024–65535`.
- If the remote port is kept as `0`, Serveo assigns a random port. (better to use `0` in most cases)

### SSH Tunnels:
- For SSH tunnel to work local port should be `22` .
- An alias is mandatory, allowing connections like:
  ```bash
  ssh -J serveo.net user@myalias
  ```

## System Requirements

- Ensure `curl`, `ssh`, and `awk` are installed.
- For TCP tunnels, `ncat` (Netcat) is required.
- Supported operating systems: Linux (any common distros).

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

## Pull Requests

The `script.sh` file is provided to help you understand the code and to encourage your contributions. After making changes, submit a pull request, and I will merge it into the main branch.
After a particular number of changes to this file a new version of this tool (`nethost_*.*.*.deb`) will be released.

> [!TIP]
> Instead of the keyword `nhost` you can also use `serveo` on the terminal.
> 

> [!NOTE]
> Serveo.net is often reported as being unreliable or down for extended periods.
> ### ![serveo](https://img.shields.io/uptimerobot/status/m798198859-ecf1064c616a7c3cbfac9734)

