# Lazydocker

[Lazydocker](https://github.com/jesseduffield/lazydocker) is a TUI for Docker to quickly access and manage container logs, stats, volumes, and even allows to quickly enter a running container with a shell.

The latest version can be found [here](https://github.com/jesseduffield/lazydocker/releases/latest).

```bash
wget -O lazydocker.tar.gz https://github.com/jesseduffield/lazydocker/releases/download/v0.20.0/lazydocker_0.20.0_Linux_x86_64.tar.gz
tar xfz lazydocker.tar.gz --directory=.
for nomad in $(jq -r keys[] ~/nomad-env.json); do
  scp lazydocker $nomad:/usr/local/sbin/lazydocker
done
```
