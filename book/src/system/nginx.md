# Nginx job file

The Nginx job file will run as system type and spawn a worker on all Nomad hosts in the defined datacenter.

The provided template will create a Nginx upstream and location block for each Nomad service with the following tags:

- "public-html"
- A key/value map converted to JSON containing "path" for the location block

In example:

```
tags = ["public-http", jsonencode({
  path = "/mutagen/status.json"
})]
```

Each machine with a healthy service instance will be added as upstream.

---

This job file must be passed a "server_name" variable value:

```bash
nomad run -var server_name=nomad.debinux.de nginx.nomad
```

Alternatively a default value can be assigned on top of the job file.

```bash
{{#include ../../../../jobs/nginx/nginx.nomad}}
```
