# nomad-helper

> nomad-helper is a tool meant to enable teams to quickly onboard themselves with nomad, by exposing scaling functionality in a simple to use and share yaml format.

Prebuilt binaries can be downloaded [on GitHub (nomad-helper)](https://github.com/seatgeek/nomad-helper/releases).

It is especially useful to quickly attach to tasks:

```bash
user@user-UX490UA:~/NAS/hetzner-data/nomad-data/mdBook on  main
🕙 xxx ❯ nomad-helper attach
? Please select a job:
   0) databases
   1) lb
   2) sshd
   3) sync
! Pick a number: 0
* Selected databases
? Please select an allocation:
  0) 588e06ad - databases.mariadb[0] @ nomad-3
  1) 9b44f460 - databases.cache[0] @ nomad-1
  2) d2fbb78d - databases.index[0] @ nomad-1
! Pick a number: 1
* Selected 9b44f460 - databases.cache[0] @ nomad-1
* Autoselected task 'redis'
* Going to attach to task 'redis' on 'nomad-1' with command 'bash'

root@03fe7fa3f31a:/data#
```
