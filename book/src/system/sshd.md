# SSHd job file

**Important**: Task names must be unique.

This job does require levant.

Levant was used to create a dynamic amount of tasks depending on the configuration found in "variables.json".

Moreover Levant offers the ability to outsource files to be included when rendering the job. This greatly improves the readability of the job file.

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
