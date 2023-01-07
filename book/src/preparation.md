# Preparation

For my setup I spawned three CX11 machines on Hetzer Cloud named nomad-1, nomad-2 and nomad-3.

Each node has a public facing IPv4 and IPv6 address as well as two internal networks for client and server traffic:

- `10.100.100.0/24` is the network used for Nomad server agents
- `10.200.200.0/24` is the network used for Nomad client agents

Both networks are **not** isolated from eachother. Our client agents need to talk to our server agents using RPC via `4647/tcp`.

IPs assigned in these networks must be static.

Nomad server agents mostly use gossip on `4648/tcp+udp` within their own class for consensus decision-making and other communication.

The network used for Nomad server agent gossip **could be** isolated from the other networks and abstracted as cross-regional network over VPN. Gossip traffic will be encrypted in our setup, a network for this kind of traffic should not add extra latency by using an overly complex encryption.

Besides the machine hostname I will assign two more names to each host:

```yaml
Machine hostname nomad-1:
  DNS:
    - Server name in cluster: server-1.nomad.cluster
    - Client name in cluster: client-1.nomad.cluster

Machine hostname nomad-2:
  DNS:
    - Server name in cluster: server-2.nomad.cluster
    - Client name in cluster: client-2.nomad.cluster

Machine hostname nomad-3:
  DNS:
    - Server name in cluster: server-3.nomad.cluster
    - Client name in cluster: client-3.nomad.cluster
```

A simple for-loop will setup hostnames and modify the hosts file accordingly in the next steps.

This is my temporary ssh config file. I write "temporary" as I do not prefer to use root as default user for anything, but it will help a lot to create, append, or copy configurations between nodes while setting up the cluster:

```yaml
Host nomad-1
  User root
  Hostname 5.75.230.14
  Port 22
  LocalForward 127.0.0.1:4646 10.100.100.2:4646
  ForwardAgent yes

Host nomad-2
  User root
  Hostname 5.75.230.15
  LocalForward 127.0.0.1:4647 10.100.100.3:4646
  Port 22
  ForwardAgent yes

Host nomad-3
  User root
  Hostname 5.75.230.16
  LocalForward 127.0.0.1:4648 10.100.100.4:4646
  Port 22
  ForwardAgent yes
```

As you see I will use agent forwarding. I will be able to jump from/to each worker using my forwarded agent, that is as long as I carry the SSH agent of course. You can do as you like.

To access the web UI I added a port forwarding to expose the server agents HTTP listener to my local machine. We will also encrypt HTTP traffic and require to authenticate using a client certificate.

---

To make life easier I will use JSON in combination with "jq" to pre-seed a set of variables to use in different occasions. I will write this data to `~/nomad-env.json`:

```json
{
  "nomad-1": {
    "server_name": "server-1.nomad.cluster",
    "client_name": "client-1.nomad.cluster",
    "server": "10.100.100.2",
    "client": "10.200.200.2",
    "server_interface": "ens10",
    "client_interface": "ens11"
  },
  "nomad-2": {
    "server_name": "server-2.nomad.cluster",
    "client_name": "client-2.nomad.cluster",
    "server": "10.100.100.3",
    "client": "10.200.200.3",
    "server_interface": "ens10",
    "client_interface": "ens11"
  },
  "nomad-3": {
    "server_name": "server-3.nomad.cluster",
    "client_name": "client-3.nomad.cluster",
    "server": "10.100.100.4",
    "client": "10.200.200.4",
    "server_interface": "ens10",
    "client_interface": "ens11"
  }
}
```

Now **validate** the correct evaluation using "jq":

```bash
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  cat << TEST

Hostname ${nomad}:
  - Server name in cluster: $(jq -r ".\"$nomad\".server_name" ~/nomad-env.json)
  - Client name in cluster: $(jq -r ".\"$nomad\".client_name" ~/nomad-env.json)
  - Client address $(jq -r ".\"$nomad\".client" ~/nomad-env.json) on interface $(jq -r ".\"$nomad\".client_interface" ~/nomad-env.json)
  - Server address $(jq -r ".\"$nomad\".server" ~/nomad-env.json) on interface $(jq -r ".\"$nomad\".server_interface" ~/nomad-env.json)

TEST
done
```

This is a great opportunity to get an overview of the setup:

```
Hostname nomad-1:
  - Server name in cluster: server-1.nomad.cluster
  - Client name in cluster: client-1.nomad.cluster
  - Client address 10.200.200.2 on interface ens11
  - Server address 10.100.100.2 on interface ens10


Hostname nomad-2:
  - Server name in cluster: server-2.nomad.cluster
  - Client name in cluster: client-2.nomad.cluster
  - Client address 10.200.200.3 on interface ens11
  - Server address 10.100.100.3 on interface ens10


Hostname nomad-3:
  - Server name in cluster: server-3.nomad.cluster
  - Client name in cluster: client-3.nomad.cluster
  - Client address 10.200.200.4 on interface ens11
  - Server address 10.100.100.4 on interface ens10
```
