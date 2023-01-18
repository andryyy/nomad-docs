./mdbook build book
git add -A
git commit -m "$(date)"
git push origin main
rsync -a --chmod=ugo=rw,-X --numeric-ids --chown 101:101 book/book/ nomad-1:/opt/nomad-vols/shared-data/101_101/nomad-docs/
