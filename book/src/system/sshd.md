# SSHd job file

**Important**: Task names must be unique.

```bash
{{#include ../../../../jobs/sshd/variables.json}}
```

```bash
{{#include ../../../../jobs/sshd/set_var.sh}}
```


```bash
{{#include ../../../../jobs/sshd/includes/permfix}}
{{#include ../../../../jobs/sshd/includes/prepare.sh}}
```

```bash
{{#include ../../../../jobs/sshd/sshd.nomad}}
```

```bash
{{#include ../../../../jobs/sshd/run_sshd.sh}}
```
