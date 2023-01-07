# Basic setup

I will start by setting the hostname, timezone, and populating the node hostnames (manually). My scripts will be run using a bash shell.

```bash
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  ssh $nomad bash <<EOF
    hostnamectl set-hostname $nomad;
    timedatectl set-timezone Europe/Berlin;
    cat << HOSTS >> /etc/hosts
# Nomad server agents
10.100.100.2 server-1.nomad.cluster
10.100.100.3 server-2.nomad.cluster
10.100.100.4 server-3.nomad.cluster
# Nomad client agents
10.200.200.2 client-1.nomad.cluster
10.200.200.3 client-2.nomad.cluster
10.200.200.4 client-3.nomad.cluster
HOSTS
    apt install jq -y
EOF
done
```

Some basic aliases; you may skip this part.

```bash
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  ssh $nomad bash <<'EOF'
cat <<'ALIASES'> ~/.bashrc
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -la'
alias l='ls $LS_OPTIONS -lA'
ALIASES
EOF
done
```

The Docker driver will be used, so Docker needs to be installed on each Nomad client. Nomad will automatically detect the driver.

This is a lazy approach to install Docker. Piping shell scripts from the internet is never a good idea, keep that in mind.

```bash
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  ssh $nomad bash <<'EOF'
  curl -fsSL https://get.docker.com | sh
EOF
done
```

Let's add the Hashicorp repository and install Nomad. The default service will be stopped (if running) and disabled, autocomplete for Nomad is installed:

```bash
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  ssh $nomad bash <<'EOF'
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list
    apt update
    apt install nomad -y
    systemctl stop nomad.service
    systemctl disable nomad.service
    systemctl mask nomad.service
    nomad -autocomplete-install
EOF
done
```

Now for the last requirement I will download and extract the CNI plugins to `/opt/cni/bin` where they will be picked up by Nomad automatically.

The CNI plugins are necessary for the "nomad" bridge to be created.

The "port bindings" created in a bridged network mode are solely DNAT'ed to their dynamic destination, this is a concept I was not aware of when starting with Nomad.

We will not see a listener on that port using `ss` or `netstat`, instead we can call `iptables -L CNI-HOSTPORT-DNAT -t nat -n` to check for their existence. Running the command *now* will result in either an error or an empty return as there is no chain available by that name.

Version 1.1.1 may be deprecated by the time of reading:

```bash
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  ssh $nomad bash <<'EOF'
    mkdir -p /opt/cni/bin
    curl -L -o cni-plugins.tgz https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
    tar -C /opt/cni/bin -xzf cni-plugins.tgz
EOF
done
```
