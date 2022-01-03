namespace :bundle do
  desc 'Updates the ruby-advisory-db then runs bundle-audit'
  task :audit do
    require 'bundler/audit/cli'
    Bundler::Audit::CLI.start ['update']
    Bundler::Audit::CLI.start %w[check --ignore CVE-2015-9284]
  end
end
