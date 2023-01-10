# Server agent configuration

Let's start with the server configuration. In case you wonder and missed the hint in the previous chapter: there is no need to define the host volume in a server agent configuration.

The server agent will be aware of the capabilities of a client and delegate tasks to matching client agents. A client missing a host volume will not be taken into consideration for a deployment.

**Hint:** See the `gossip_key` variable, don't miss it.

```bash
gossip_key=$(openssl rand -base64 32)
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  server_ip=$(jq -r ".\"$nomad\".server" ~/nomad-env.json)
  ssh $nomad bash <<EOF
    cat <<SERVER > /etc/nomad.d/server.hcl
# data_dir will be suffixed by the agent configuration automatically: server/ or client/
data_dir = "/opt/nomad/data"

# We deploy in Falkenstein, this is only important in job files to be created later on.
datacenter = "falkenstein"

# All services of the server agent will bind to the bind_addr defined IP address: rpc, http and serf (gossip)
# The bind_addr can be overruled by the addresses stanza where each service IP binding can be defined by itself.
# Ports can be defined using the ports stanza.
# It seems like you also need to define an advertise stanza in conjunction with the addresses stanza.
# This is especially helpful with NAT: the advertise stanza also accepts ports.
# For a better understanding we will use bind_addr, ports, addresses and advertise stanzas using all default ports.
# This will do exactly the same as only defining bind_addr, I just want to make you aware of what is possible:
# Note: External IPs are being discovered by the network fingerprinting mechanism in Nomad.

bind_addr = "${server_ip}"
ports {
  http = 4646
  rpc  = 4647
  serf = 4648
}
advertise {
  http = "${server_ip}:4646"
  rpc  = "${server_ip}:4647"
  serf = "${server_ip}:4648"
}
addresses {
  http = "${server_ip}"
  rpc  = "${server_ip}"
  serf = "${server_ip}"
}

server {
  # Yes, we are a server agent
  enabled = true
  # We will only bootstrap the cluster when all server agents can gossip
  bootstrap_expect = 3
  server_join {
    # Our join mechanism is to retry until success. We can define ourself here, too, that's fine.
    # Use hostnames as defined in the certificate!
    retry_join = ["server-1.nomad.cluster", "server-2.nomad.cluster", "server-3.nomad.cluster"]
  }
  # The key for gossip encryption created previously using openssl.
  # The value is the same for all nodes obviously.
  encrypt = "${gossip_key}"
}

client {
  # Not a client agent
  enabled = false
}

tls {
  # We do want to encrypt RPC traffic
  rpc = true
  # We do want to encrypt HTTP traffic
  http = true
  ca_file = "/etc/nomad.d/pki/nomad-ca.pem"
  cert_file = "/etc/nomad.d/pki/server.pem"
  key_file = "/etc/nomad.d/pki/server-key.pem"

  # verify_server_hostname will require the role ("client", "server") and region ("global") to be verified.
  # Setting it to false results in only the CA to be verified.
  # Servers from other or unwanted regions could join a cluster when they should not be allowed to.
  verify_server_hostname = true

  # We do only want to allow access to the HTTP API using a client certificate.
  # Affects curl, Nomad CLI, and others
  # We will catch this up later.
  verify_https_client = true
}
SERVER
EOF
done
```

After validating the server configuration we are now able to enable and start the server agent service:

```bash
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  ssh $nomad bash <<'EOF'
    systemctl enable --now nomad-server.service;
EOF
done
```

I can now login to one of my three Nomad machines and check wether a cluster leader was elected:

```bash
root@nomad-1:~# nomad server members
Name            Address       Port  Status  Leader  Raft Version  Build  Datacenter   Region
nomad-1.global  10.100.100.2  4648  alive   false   3             1.4.3  falkenstein  global
nomad-2.global  10.100.100.3  4648  alive   true    3             1.4.3  falkenstein  global
nomad-3.global  10.100.100.4  4648  alive   false   3             1.4.3  falkenstein  global
```

Sometimes you may find yourself in a situation where a server agent does not feel like joining the gang.

Often it is a matter of an existing Nomad data directory bootstrapped from a previous configuration. Since we are just starting a new cluster, we can safely stop the service and remove the data directories. Keep in mind to recreate it with proper permission and ownership as described in the previous chapter.

Whatever you decide to do: your first contact point should always be the log files: `journalctl -u nomad-server -f`
