# Layer Payment SDK for Ruby On Rails

1.Install NodeJs v12 or higher

2.Use NodeJs command prompt to install rest

3.Install Ruby - http://rubyinstaller.org/

4.Install Rails - gem install rails

5.Install Yarn - https://classic.yarnpkg.com/en/docs/install/#windows-stable

6.Close and re-open command prompt. Go to location where you want to create project


** For details on Ruby On Rails installation and developement. Please follow respective documentations and tutorials.

https://www.tutorialspoint.com/ruby-on-rails/rails-installation.htm

https://errorsandfixes.bookmark.com/webpacker-configuration-file-not-found-webpacker-yml


** This Ruby On Rails application uses 'rubygems', 'openssl', 'base64', 'securerandom', 'faraday' and 'json' libraries.


1. Create a new Ruby project as -
	
	> $ rails new ror_layerpayment

2. Copy following files -

	app\assets\images\logo.png
	
	app\controllers\test_controller.rb
	
	app\views\test\\*
	
	config\routes.rb
	
	
3. Open ror_layerpayment\app\controllers\test_controller.rb

4. Modify values of Configurable parameters from line 12,13,14,15 as per credentials and callback path. Save the file.

5. Change to ror_layerpayment directory/folder and run server -

	> rails s

6. Open browser and access server e.g. http://localhost:3000

------------------------------------------------
Manifest error: run below commands in app folder
------------------------------------------------
rm -rf node_modules

rails assets:clobber

yarn

rails webpacker:install

rails assets:precompile

./node_modules/.bin/webpack



--------------
gemfile
--------------
gem 'faraday'

bundle install

bundle info faraday

