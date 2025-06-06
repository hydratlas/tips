# k3s

Install and configure k3s (Lightweight Kubernetes) on RHEL and Debian-based systems.

## Requirements

- Supported OS families: RedHat (RHEL, CentOS, Rocky, AlmaLinux) and Debian (Debian, Ubuntu)
- Root or sudo access
- Internet connectivity for downloading k3s installer

## Role Variables

```yaml
# Installation method
k3s_install_method: "script"  # Options: script, binary

# k3s version (leave empty for latest)
k3s_version: ""

# Server or agent mode
k3s_server_or_agent: "server"  # Options: server, agent

# k3s server URL (required for agent mode)
k3s_server_url: ""

# k3s token (required for agent mode, auto-generated for server)
k3s_token: ""

# Additional k3s install options
k3s_install_options: ""

# k3s service name
k3s_service_name: "k3s"

# Enable k3s service
k3s_service_enabled: true

# Start k3s service
k3s_service_state: "started"

# k3s configuration
k3s_config:
  write-kubeconfig-mode: "0644"
  disable:
    - traefik
    - servicelb

# SELinux configuration (RHEL only)
k3s_selinux_enabled: true

# Firewall configuration
k3s_manage_firewall: true
k3s_firewall_ports:
  - port: 6443
    proto: tcp
    comment: "Kubernetes API Server"
  - port: 10250
    proto: tcp
    comment: "Kubelet metrics"
  - port: 10251
    proto: tcp
    comment: "kube-scheduler"
  - port: 10252
    proto: tcp
    comment: "kube-controller"
  - port: 8472
    proto: udp
    comment: "Flannel VXLAN"
```

## Dependencies

None

## Example Playbook

### Single server installation

```yaml
- hosts: k3s_server
  become: yes
  roles:
    - role: k3s
      vars:
        k3s_server_or_agent: server
```

### Multi-node cluster

```yaml
# Install server first
- hosts: k3s_server
  become: yes
  roles:
    - role: k3s
      vars:
        k3s_server_or_agent: server

# Then install agents
- hosts: k3s_agents
  become: yes
  roles:
    - role: k3s
      vars:
        k3s_server_or_agent: agent
        k3s_server_url: "https://{{ hostvars['k3s_server']['ansible_default_ipv4']['address'] }}:6443"
        k3s_token: "{{ hostvars['k3s_server']['k3s_node_token'] }}"
```

### Custom configuration

```yaml
- hosts: k3s_nodes
  become: yes
  roles:
    - role: k3s
      vars:
        k3s_version: "v1.28.4+k3s1"
        k3s_config:
          write-kubeconfig-mode: "0600"
          disable:
            - traefik
            - servicelb
            - metrics-server
          cluster-cidr: "10.42.0.0/16"
          service-cidr: "10.43.0.0/16"
```

## License

BSD

## Author Information

Created for home infrastructure automation