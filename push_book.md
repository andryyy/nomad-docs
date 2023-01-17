git add -A
git commit -m "$(date)"
git push origin main
scp -r book/ nomad-1:/opt/nomad-vols/shared-data/1000_1000/nomad-docs/
