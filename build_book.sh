./mdbook build book
git add -A
git commit -m "$(date)"
git push origin main
echo Waiting a few seconds before pulling data from GH via job file...
sleep 10
cd ../jobs/nginx
bash run_nginx.sh

