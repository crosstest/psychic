source 'https://rubygems.org'

source 'https://rubygems.org'

gemspec

# This hack inspired by rspec...
branch = begin
           File.read(File.expand_path('../maintenance-branch', __FILE__)).chomp
         rescue
           'master'
         end

%w(crosstest-core).each do |lib|
  library_path = File.expand_path("../../#{lib}", __FILE__)
  gem_name = lib.start_with?('crosstest') ? lib : "crosstest-#{lib}"
  if File.exist?(library_path) && !ENV['USE_GIT_REPOS']
    gem gem_name, path: library_path
  else
    gem gem_name, git: "git://github.com/crosstest/#{lib}.git", branch: branch
  end
end

gem 'pry'
gem 'rouge'
