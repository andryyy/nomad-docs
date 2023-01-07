./mdbook build book
git add -A
git commit -m "$(date)"
git push origin main
cd ../jobs/nginx
bash run_nginx.sh

