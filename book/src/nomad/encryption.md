# Encryption

## Gossip (server nodes)

Gossip is traffic between server nodes on port 4648/tcp/udp. Gossip traffic is not read by a Nomad client. Gossip is encrypted by using symmetric encryption, so all server nodes will share the same secret given as base64 formatted string. The maximum length is 32 bytes.

I will generate random bytes for gossip encryption between Nomad servers when populating the server configuration file.

## mTLS encryption for HTTP and RPC traffic

All nodes, no matter their role, talk RPC (4647/tcp) and HTTP (4646/tcp) traffic.

HTTP is obviously used for the web UI but also necessary for running nomad commands via terminal as Nomad is fully API-driven - as most (all?) Hashicorp products are.

RPC is used for communication between clients and servers.

### Preface: How does TLS in Nomad work?

It is helpful to understand the basics of what Nomad actually verifies using which name using which protocol.

#### RPC

For **RPC communication** Nomad agents will use a pseudo name not resolved in DNS depending on the agent role:

- `client.$region.nomad`
- `server.$region.nomad`

**Quick note**: The default value for "region" is "global", I will get back to this later. `$region` is merely a placeholder here.

There are two modes for verification where "verify_server_hostname" can be either "true" or "false".

"verify_server_hostname" set to **false** will only require the cluster to use certificates signed by the same CA.

"verify_server_hostname" set to **true** requires not only the CA but also the region to match. A Nomad agent using `server.us-west.nomad` would not be able to join a cluster in the region `eu-west` for example.

In theory a single certificate containing both client and server pseudo names would be sufficient for Nomad no matter the agent role. You don't **have to** add more names for a functional setup, but read on...

---

#### HTTP

HTTP as the second component covered by mTLS will use the **same certificate as RPC**.

TLS can be enabled independently for RPC and HTTP, but only one shared certificate can be defined for both services.

**Valid certificates for the HTTP endpoints should be preferred.**
The certificates will include the server as well as client agents name as populated in DNS, i.e. "client-1.nomad.cluster" and  "server-1.nomad.cluster".

Breaking the certificates down to only include the pseudo name (i.e. "client.global.nomad") and the specific name of the agent (i.e. "client-1.nomad.cluster") does not offer higher security compared to a combined certificate. As of writing this documentation Nomad is not able to read a CRL to invalidate certificates automatically, but in an existing PR (4901) the developers discussed the implementation of such a mechanism.

One combined certificate for all client agents and one for all server agents is fine.

A powerful access control for the HTTP endpoint is setting `verify_https_client` to **true** and enforce a policy to require a valid client certificate signed by the same CA. All requests to the HTTP endpoint including the API are covered. When set to **false**, the channel is encrypted but there is no mechanism to restrict.

**Note**: Creating and importing a client certificate as ".p12" file into the browser is explained in the course of this document.

As long as CRLs are not supported, short-lived client certificates might be something to look into.

A better and more granular method to restrict access in general is using Nomads ACL system, which can be quite complex.

#### Our setup

This documentation will follow an easy to reproduce scheme:

- **One** certificate for all Nomad client agents:
  - Hostnames in certificate: `client.global.nomad`, `*.nomad.cluster`

- **One** certificate for all Nomad server agents:
  - Hostnames in certificate: `server.global.nomad`, `*.nomad.cluster`

- A client certificate to authenticate against Nomads HTTP endpoint

As wildcard certificates are supported by Nomad, we will make use of that.

**Important**: "server.global.nomad" is used to address any server agent in the region "global". This is the default region in Nomad we will adopt to. Changing the region to something like `eu-west` would require to append `server.eu-west.nomad` as hostname. This setup will validate the region.

### Bootstrap a minimal CA

I will use nomad-1 to bootstrap a minimal CA using "cfssl" as described in the Nomad documentation:

```bash
root@nomad-1:~ # apt install golang-cfssl
root@nomad-1:~ # mkdir /etc/nomad.d/pki ; cd /etc/nomad.d/pki
root@nomad-1:/etc/nomad.d/pki #
```

Create the CA with default values:

```bash
root@nomad-1:/etc/nomad.d/pki # cfssl print-defaults csr | cfssl gencert -initca - | cfssljson -bare nomad-ca
```

At this point the CA is alive.

A certificate template is created, the fields should be pretty self-explanatory:

```bash
root@nomad-1:/etc/nomad.d/pki # cat <<EOF> /etc/nomad.d/pki/cfssl.json
{
  "signing": {
    "default": {
      "expiry": "87600h",
      "usages": ["signing", "key encipherment", "server auth", "client auth"]
    }
  }
}
EOF
```

### Server agent certificate

```bash
root@nomad-1:/etc/nomad.d/pki # echo '{}' | cfssl gencert \
  -ca=/etc/nomad.d/pki/nomad-ca.pem \
  -ca-key=/etc/nomad.d/pki/nomad-ca-key.pem \
  -config=/etc/nomad.d/pki/cfssl.json \
  -hostname="server.global.nomad,*.nomad.cluster" - | cfssljson -bare server
```

### Client agent certificate

```bash
root@nomad-1:/etc/nomad.d/pki # echo '{}' | cfssl gencert \
  -ca=/etc/nomad.d/pki/nomad-ca.pem \
  -ca-key=/etc/nomad.d/pki/nomad-ca-key.pem \
  -config=/etc/nomad.d/pki/cfssl.json \
  -hostname="client.global.nomad,*.nomad.cluster" - | cfssljson -bare client
```

### Client authentication certificate

This certificate does not contain hostnames and is solely used to authenticate to the HTTP endpoint:

```bash
root@nomad-1:/etc/nomad.d/pki # echo '{}' | cfssl gencert -ca=nomad-ca.pem -ca-key=nomad-ca-key.pem -profile=client \
  - | cfssljson -bare cli
```

### Seeding certificates, cleanup, and details

Change the owner to nomad and its default group:

```bash
root@nomad-1:/etc/nomad.d/pki # chown -R nomad: /etc/nomad.d/pki
```

Now let's copy the pki data to all nodes. **You should move the CA key to a host outside the Nomad cluster.**

```bash
root@nomad-1:/etc/nomad.d/pki # scp -r /etc/nomad.d/pki server-2.nomad.cluster:/etc/nomad.d/ ; ssh server-2.nomad.cluster chown -R nomad: /etc/nomad.d/pki
root@nomad-1:/etc/nomad.d/pki # scp -r /etc/nomad.d/pki server-3.nomad.cluster:/etc/nomad.d/ ; ssh server-3.nomad.cluster chown -R nomad: /etc/nomad.d/pki
```

Before populating the server and client configuration files, we will export some variables to communicate with the corresponding HTTP server of the local Nomad server agent.

It does not matter wether or not Nomad is running at this point.

We are using the server agents DNS name as NOMAD_ADDR. These names are part of the created server certificate.

```bash
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  ssh $nomad bash <<EOF
cat <<PROFILE>> ~/.profile
export NOMAD_ADDR=https://$(jq -r ".\"$nomad\".server_name" ~/nomad-env.json):4646
export NOMAD_CACERT=/etc/nomad.d/pki/nomad-ca.pem
export NOMAD_CLIENT_CERT=/etc/nomad.d/pki/cli.pem
export NOMAD_CLIENT_KEY=/etc/nomad.d/pki/cli-key.pem
PROFILE
EOF
done
```

### Creating a .p12 file

I do want to access the Nomad web UI with my browser, so the CLI certificate must be imported into my local Firefox.

A proper ".p12" file should be password protected. Some browsers or operation systems will refuse to import a ".p12" file without a password set (see iOS).

```bash
root@nomad-1:/etc/nomad.d/pki # openssl pkcs12 -export \
  -in cli.pem \
  -inkey cli-key.pem \
  -out nomad-cli.p12 \
  -name "Nomad CLI"
```

**Important**: You may find yourself not being able to import the client certificate in iOS when using OpenSSL >= v3.
To be able to create an importable file, you need to append the `-legacy` flag to the command above.

Scrolling back to the top you may remember the port forwarding added to my `.ssh/config` file. That's how I will be able to access the UI whenever I need to.
