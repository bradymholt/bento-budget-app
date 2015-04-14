namespace :deploy do
	task :precompile => ["assets:clean"] do
		puts "rake assets:precompile RAILS_ENV=production"
		puts `rake assets:precompile RAILS_ENV=production`
	end

	desc "Deploy"
	task :all => [:precompile] do
		servers = ["bude@geekytidbits.com"]
		servers.each do |server|
			puts "copying files to #{server}..."
			puts `rsync -rvuz --delete ~/dev/bento-app/ #{server}:app --exclude='.git/' --exclude='log/' --exclude='tmp/cache'`
			puts "executing deployment commands on #{server}..."
			puts `ssh #{server} 'cd ~/app && RAILS_ENV=production bundle exec rake deploy:remote'`
		end
	end

	task :remote => ["db:migrate", "tmp:clear", "log:clear"] do
		puts "bundle install"
		puts `bundle install`
		puts "touch tmp/restart.txt"
		puts `touch tmp/restart.txt`
		puts "Deploy Successful!"
	end
end