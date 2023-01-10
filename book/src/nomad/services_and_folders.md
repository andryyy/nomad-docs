# Services and folders

Nomad will be running as server and client agent on the same host. By default a Nomad service file will run the agent as root, no matter its purpose: being a client or a server.

Nomad recommends to run the client agent as root while protecting its data store from unprivileged access.
A client agent needs to spawn containers, create protected environments ("chroot") and do some other low level operations which mostly require root(-like) access. It is not impossible to use a non-root user, but that will require thoroughly testing.

The server agent should run with lowest privileges with full access to its data directory.

Another consideration is to remove the OOM score from the server agent as well as any limit adjustments while keeping them active for the client.

It is very important for the client not to be killed due to other processes claiming system resources it has no control over. The most important reason a client should not to be placed on the same node as a server is unpredicted availability of system resources. This will not apply to all workloads and also depends a lot on the expected usage in relation to available resources.
Preventing it from being killed is not a solution to the problem, but it will help the cluster to notice a problem and act on it.


## Nomad data folder structure

Making sure to be using a proper Nomad data folder structure includes setting the ownership and permissions accordingly for each agent configuration. This step is necessary due to the nature of a default Nomad installation to be run as root no matter what. Default data directories can be problematic.

```bash
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  ssh $nomad bash <<'EOF'
    # This may be dangerous, validate you are not removing a directory in production!
    rm -rf /opt/nomad/data
    # (Re-)Create the folder structure
    mkdir -p /opt/nomad/data/{server,client}
    # All belong to nomad
    chown -R nomad: /opt/nomad
    # Except for client data, we can lock this folder up
    chown root: /opt/nomad/data/client
    chmod 700 /opt/nomad/data/client
EOF
done
```

## Create a host volume on all client agents

For host volumes used in any Nomad job we will create a new directory `/opt/nomad-vols` containing `shared-data` for the directory synchronized by Mutagen:

```bash
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  ssh $nomad bash <<'EOF'
    mkdir -p /opt/nomad-vols/shared-data;
    chown root: /opt/nomad-vols
EOF
done
```

**Hint**: Using a host volume in a protected environment ("chroot") requires permissions to be set to nobody:nogroup for the task to be able to write to it. There is no need to act now, this is just a friendly note to remember.

A host volume is defined in a client configuration.

## Server agent service files

Create the service files for the **server** agents on each machine:

```bash
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  ssh $nomad bash <<'EOF'
    cat <<'SERVICE' > /etc/systemd/system/nomad-server.service
[Unit]
Description=Nomad server
Documentation=https://nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/bin/nomad agent -config /etc/nomad.d/server.hcl
User=nomad
Group=nomad
Restart=on-failure
RestartSec=2
KillMode=process
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
SERVICE
EOF
done
```


## Client agent service files

Create the service files for the **client** agents on each machine:

```bash
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  ssh $nomad bash <<'EOF'
    cat <<'SERVICE' > /etc/systemd/system/nomad-client.service
[Unit]
Description=Nomad client
Documentation=https://nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/bin/nomad agent -config /etc/nomad.d/client.hcl
Restart=on-failure
RestartSec=2
KillMode=process
KillSignal=SIGINT
LimitNOFILE=65536
LimitNPROC=infinity
TasksMax=infinity
OOMScoreAdjust=-1000

[Install]
WantedBy=multi-user.target
SERVICE
EOF
done
```
