# Accessing the client

As a quick note before getting into the topic I want to remark that connecting to the HTTP API of the client agent using the "nomad" binary is not something Nomad administrators will have to do daily. Also remember that Nomad client agents are usually not installed on the same machine as Nomad server agents. This is a self-made problem.

Commands related to the Nomad client agent will not work as "NOMAD_ADDR" is set to the local servers agent IP address:

```bash
root@nomad-1:~# nomad node status -self
Nomad not running in client mode
```

Setting the value of "NOMAD_ADDR" to a clients IP binding does not result in a successful response either:

```bash
root@nomad-1:~# NOMAD_ADDR=https://10.200.200.2:4646
root@nomad-1:~# nomad node status -self
Error querying agent info: failed querying self endpoint: Get "https://10.200.200.2:4646/v1/agent/self": x509: cannot validate certificate for 10.200.200.2 because it doesn't contain any IP SANs
```

**Use a valid hostname used in the client agents certificate.**

The "nomad" binary will refuse to connect to a clients IP address as we did not include any in our certificate. So let's write a tiny wrapper to access the client correctly:

```bash
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  ssh $nomad bash <<'EOF'
cat <<'PROFILE'>> ~/.profile
complete -C /usr/bin/nomad nomad_client # for autocomplete
nomad_client() { local NOMAD_ADDR=https://client-1.nomad.cluster:4646; nomad "${@}"; }
PROFILE
EOF
done
```

Now we can query the Nomad client agent using the wrapper function:

```bash
root@nomad-n:~# nomad_client node status -self -verbose
```

