#!/bin/bash

#set -e

git add -A
git commit -m "deploying"
git push

cd ~/dev/bento-app
git pull
echo "rake assets:precompile"
bundle exec rake assets:precompile RAILS_ENV=production
echo "copying files..."
rsync -rvuz --delete ~/dev/bento-app/ bude@app.bentobudget.com:app --exclude='.git/' --exclude='log/' --exclude='tmp/cache'
echo "removing local precompiled assets"
rm -r ~/dev/bento-app/public/assets/*
echo "bundle install"
ssh bude@app.bentobudget.com 'cd ~/app && bundle install'
echo "rake db:migrate"
ssh bude@app.bentobudget.com 'cd ~/app && bundle exec rake db:migrate RAILS_ENV="production"'
echo "rake tmp:clear"
ssh bude@app.bentobudget.com 'cd ~/app && bundle exec rake tmp:clear'
echo "rake log:clear"
ssh bude@app.bentobudget.com 'cd ~/app && bundle exec rake log:clear'
echo "touch tmp/restart.txt"
ssh bude@app.bentobudget.com 'touch ~/app/tmp/restart.txt'
echo "Deploy Successful!"
