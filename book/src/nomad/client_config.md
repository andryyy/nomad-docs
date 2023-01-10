# Client agent configuration

The client agent configuration is a bit more technical. As described in the beginning a client agent deploys workloads on the machine it is installed on.

The client is able to fingerprint most of the hosts capabilities, but it can obvioulsy not know about host volumes you want to expose to tasks or detect networks and assign them roles.

This time we will only be using bind_addr and remove redundant comments in the configuration file.

**Important**: In the configuration below I made the Nomad client aware of two host networks:

1. "nomad-clients" via 10.200.200.0/24
2. "nomad-servers" via 10.200.200.0/24

Revalidate the correct interfaces in the JSON config file created in the beginning. The interface must match the host interface on the specific machine. The interface names do not have to be the same for all machines, the names must match though.

```bash
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  ssh $nomad bash <<EOF
  cat <<CLIENT > /etc/nomad.d/client.hcl
data_dir = "/opt/nomad/data"
datacenter = "falkenstein"
bind_addr = "$(jq -r ".\"$nomad\".client" ~/nomad-env.json)"

server {
  enabled = false
}

client {
  enabled = true
  server_join {
    retry_join = ["server-1.nomad.cluster", "server-2.nomad.cluster", "server-3.nomad.cluster"]
  }
  host_volume "shared-data" {
    path = "/opt/nomad-vols/shared-data"
    read_only = false
  }
  host_network "nomad-clients" {
    interface = "$(jq -r ".\"$nomad\".client_interface" ~/nomad-env.json)"
  }
  host_network "nomad-servers" {
    interface = "$(jq -r ".\"$nomad\".server_interface" ~/nomad-env.json)"
  }
}

tls {
  rpc = true
  http = true
  ca_file = "/etc/nomad.d/pki/nomad-ca.pem"
  cert_file = "/etc/nomad.d/pki/client.pem"
  key_file = "/etc/nomad.d/pki/client-key.pem"
  verify_server_hostname = true
  verify_https_client = true
}
CLIENT
EOF
done
```

Enable and start the client agents **after validating the client configuration**:

```bash
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  ssh $nomad bash <<'EOF'
    systemctl enable --now nomad-client.service
EOF
done
```

This is a great opportunity to check the Nomad web UI provided by the server agent. You can find `unique.network.ip-address` in the client details for each client agent listed in the UI. The network interface used to fingerprint the network details is the interface assigned the default route on your machine. This behavior can be adjusted using the "network_interface" parameter in the "client" stanza of your configuration.
