# SSHd job file

**This job does require levant.**

Levant was used to create a dynamic amount of tasks depending on the configuration found in "variables.json".

Moreover Levant offers the ability to outsource files to be included when rendering the job. This greatly improves the readability of the job file.

**Important**: Task names must be unique.

**Filename**: `sshd/variables.json`

```bash
{{#include ../../../../jobs/sshd/variables.json}}
```

**Filename**: `sshd/set_var.sh`

```bash
{{#include ../../../../jobs/sshd/set_var.sh}}
```

---

This script is called by Mutagen to fix permissions on scan problems.
Besides this script having all necessary fail-safes, Mutagen will also run some sanity checks before sending a path to this script.

**Filename**: `sshd/includes/permfix`

```bash
{{#include ../../../../jobs/sshd/includes/permfix}}
```

This script will prepare the environment.

It does read the given umask value and create an ACL file to be applied on the desired path, that is derived by the UID and GID, i.e. `/shared-data/$uid_$gid`.

Moreover a reference file and directory is installed for "permfix" to use when fixing scan problems.

The user "user" will only be allowed to call the permfix script using sudo.

**Filename**: `sshd/includes/prepare.sh`

```bash
{{#include ../../../../jobs/sshd/includes/prepare.sh}}
```

**Filename**: `sshd/sshd.nomad`

```bash
{{#include ../../../../jobs/sshd/sshd.nomad}}
```

---

The deploy script is calling `levant deploy`, which is pretty close to `nomad run`.

The script reads the required variables using the `-var-file` parameter and also adds the ability to call the script with extra parameters:

```bash
# Deploy
./run_sshd.sh
# Force-deploy
./run_sshd.sh -force
```

**Filename**: `sshd/run_sshd.sh`

```bash
{{#include ../../../../jobs/sshd/run_sshd.sh}}
```
