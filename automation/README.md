# Server Monitoring Setup Script

A simple Bash script that installs and configures monitoring components on a Linux server:

- **[node_exporter](https://github.com/prometheus/node_exporter)**: host-level metrics (CPU, memory, disk, network)
- **[cAdvisor](https://github.com/google/cadvisor)**: container metrics for Docker/containerd
- **[Fluent Bit](https://github.com/fluent/fluent-bit)**: log collection and forwarding

## Features

- Auto-detects OS and CPU architecture (`amd64` / `arm64`)
- Installs missing prerequisites (`wget`, `curl`, `unzip`)
- Downloads the release versions you specify from GitHub
- Installs binaries to `/usr/bin/`
- Creates and installs `systemd` unit files for node_exporter and cAdvisor
- Runs the Fluent Bit `install.sh`
- Cleans up temporary files after installation

## Requirements

- Debian/Ubuntu-based Linux (uses `apt-get`)
- Root privileges (run with `sudo` or as root)
- `systemd`
- Internet access to `github.com`
- Docker/containerd (for cAdvisor to report container metrics)

## Usage

```bash
chmod +x setup-monitoring.sh
sudo ./setup-monitoring.sh <node_exporter_version> <cadvisor_version> <fluent_bit_version>
```

A leading `v` in the version is optional.

### Example

```bash
sudo ./setup-monitoring.sh 1.8.2 0.49.1 3.1.9
```

> Replace the versions above with the releases you want. Check each project's GitHub releases page for the latest.

## What the Script Does

1. Checks that it is running as root
2. Creates a temporary `monitoring/` working directory
3. Installs `wget`, `curl`, and `unzip` if missing
4. Downloads node_exporter, cAdvisor, and Fluent Bit for the detected OS/architecture
5. Extracts the archives and removes the downloaded files
6. Generates `cadvisor.service` and `node_exporter.service`
7. Moves binaries to `/usr/bin/` and service files to `/etc/systemd/system/`
8. Runs the Fluent Bit `install.sh`
9. Removes the temporary `monitoring/` directory
10. Restarts the node_exporter and cAdvisor services

## Default Ports

| Service        | Port   |
|----------------|--------|
| node_exporter  | `9100` (default) |
| cAdvisor       | `8080` |

Make sure these ports are reachable by your Prometheus server (and restricted from the public internet).

## Verify the Installation

```bash
systemctl status node_exporter
systemctl status cadvisor

curl http://localhost:9100/metrics
curl http://localhost:8080/metrics
```

## Notes

- Both services run as `root`. Consider using a dedicated user in production.
- The script exits if run without root privileges or on an unsupported architecture.
- Run the script from a directory where you are fine with a temporary `monitoring/` folder being created and deleted.
