# Quick enter containers

This script refers to `nomad-env.json`.

```bash
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  ssh $nomad bash <<'EOF'
cat <<'ALIASES'>> ~/.bashrc
alias nomad_sshd='docker exec -it $(docker ps -qf name=sshd) bash'
alias nomad_sync='docker exec -it $(docker ps -qf name=sync) bash'
alias nomad_nginx='docker exec -it $(docker ps -qf name=nginx) bash'
alias nomad_mariadb='docker exec -it $(docker ps -qf name=mariadb) bash'
ALIASES
EOF
done
```
