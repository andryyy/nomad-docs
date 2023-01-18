./mdbook build book
git add -A
git commit -m "$(date)"
git push origin main
rsync -a --chmod=ugo=rwX --no-perms --progress --usermap=1000:101 --groupmap=1000:101 book/book/ nomad-1:/opt/nomad-vols/shared-data/101_101/nomad-docs/
