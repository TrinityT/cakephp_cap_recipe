require 'capistrano_colors'
require 'capistrano/ext/multistage'

set :stages, %w(production staging development )
set :default_stage, "staging"
set :use_sudo, false
set :deploy_via, :export
set :default_run_options, :pty => true

# update these parameter for your environment
set :application, "TODO: your application name"
set :site_prefix, "TODO: your application name"
set :scm, :subversion
set :repository,  "TODO: http://hoge/repos/trunk"
set :scm_user, "TODO: scm_user_name"
set :scm_password, "TODO: scm_user_password"
set :public_path, "/var/www/html"
set :cache_path, "/tmp/cache"

namespace :deploy do

  desc "finalize_update for CakePHP"
  task :finalize_update, :except => { :no_release => true } do
    # update symlink adjust CakePHP folder structure
    run "chmod -R g+w #{latest_release}/app" if fetch(:group_writable, true)
    run <<-CMD
      rm -rf #{latest_release}/app/log #{latest_release}/app/tmp/pids &&
      mkdir -p #{latest_release}/app/webroot &&
      mkdir -p #{latest_release}/app/tmp &&
      ln -s #{shared_path}/logs #{latest_release}/app/tmp/logs &&
      ln -s #{shared_path}/pids #{latest_release}/app/tmp/pids
    CMD

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = %w(img css js).map { |p| "#{latest_release}/app/webroot/#{p}" }.join(" ")
      run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
    end
  end

  desc "after finish deploy (synmbolic link...etc)"
  after "deploy:symlink", :roles => [:app] do
    # synmbolic link adjust CakePHP folder structure
    run "ln -fns #{current_path}/app/config/database.php.#{stage} #{current_path}/app/config/database.php"
    run "ln -fns #{current_path}/app/webroot #{public_path}/#{site_prefix}"
    # cache clear
    sudo "mkdir -p #{cache_path}"
    sudo "chmod 775 #{cache_path}"
    run "rm -rf #{cache_path}/*"
  end

  # Apache Restart Command for CentOS5
  # Apache start
  task :start, :roles => [:app] do
    sudo "/etc/rc.d/init.d/httpd start"
  end

  # Apache stop
  task :stop, :roles => [:app] do
    sudo "/etc/rc.d/init.d/httpd stop"
  end

  # Apache restart
  task :restart, :roles => [:app] do
    sudo "/etc/rc.d/init.d/httpd restart"
  end

end

