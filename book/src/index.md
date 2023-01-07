# Description

For our Nomad cluster to function properly, we will create three machines, where each machine is installed two agents on: a server and a client.

This is not what either Hashicorp or me recommend for production setups, but read on:

The nomad binary is able to be run as server and client agent started only once. For the sake of a proper configuration we will not stick to a single-configuration setup but create two systemd units representing a client and a server instance. We can bind each service to different internal networks and setup client and server TLS for each of them. The later seems to be more problematic when a single configuration is used as the "tls" stanza does not differentiate between client and server. We are also able to run the server agent with lower privileges and define different service specs.

This is something in between a "dev" and "prod" setup and should be fine for most workloads as long as the machines are being monitored.

But what is a server agent and what is a client agent? "I came here for Kubernetes being too complicated, now look at this" you may wonder.

The concept is actually pretty easy. Server nodes are more or less the brain of the cluster making decisions for clever deployments and orchestration in general.

A client agent is more stupid in this regard and does what it is told by a server agent. A client agent fingerprints the machine it is installed on, monitors resources, spawns containers, virtual machines or protected environments. This is why it requires higher privileges with capabilites like CAP_SYS_ADMIN and CAP_NET_ADMIN. A process running with CAP_SYS_ADMIN capabilites is almost always able to escalate to root, so Nomad client agents use root privileges to begin with.

A Nomad server agent could be placed on a smaller virtual machine while the client must be installed on a machine where workload is deployed. It is best for a client agent to not share/battle resources with other processes that it is not aware of. In theory a broken Nomad server agent could balloon up and kill the client if not configured properly.

Nomad client **and** server agents will join a **server** group.

**Networking** between Nomad server agents differs slightly from client agent network requirements: A Nomad server cluster should be able to exchange information with less than 10 ms delay. Client agents do not take part in a quorum and work fine with 100 ms latency and higher.


