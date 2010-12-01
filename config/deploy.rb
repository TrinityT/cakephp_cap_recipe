require 'capistrano/ext/multistage'

set :stages, %w(production staging development)
set :default_stage, "staging"
set :use_sudo, false
set :deploy_via, :export
set :default_run_options, :pty => true

# �ȉ��p�����[�^�����ɉ����ď���������
set :application,  "TODO: your application name"
set :scm,          "TODO: your scm type ex) subversion"
set :repository,   "TODO: your scm repository url ex) http://hoge/repos/trunk"
set :scm_user,     "TODO: scm_user_name"
set :scm_password, "TODO: scm_user_password"
set :public_path,  "TODO: your web server public folder path ex) /var/www/html"
set :cache_path,   "TODO: your CakePHP application cache folder ex) /tmp/cache"

namespace :deploy do

  desc "CakePHP�p��finalize_update���㏑������"
  task :finalize_update, :except => { :no_release => true } do
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

  desc "�W���̃V���{���b�N���蒼�����s��ɍs���������L�q����"
  after "deploy:symlink", :roles => [:app] do
    # �Q�l�܂łɈȉ��ɉ��_������L�ځB

    # ex1) database.php�t�@�C���������ɉ����ăV���{���b�N�����N�𒣂蒼��
    #      production�Ŏ��s�����ꍇ�Aapp/config/database.php.production��app/config/database.php�ƂȂ�B
    # run "ln -fns #{current_path}/app/config/database.php.#{stage} #{current_path}/app/config/database.php"

    # ex2) webroot��web�T�[�o���J�t�H���_��ɃA�v���P�[�V�������ŃV���{���b�N�����N�𒣂�
    # run "ln -fns #{current_path}/app/webroot #{public_path}/#{application}"

    # ex3) CakePHP�̃L���b�V���t�H���_���N���A����B
    # sudo "mkdir -p #{cache_path}"
    # sudo "chmod 775 #{cache_path}"
    # run "rm -rf #{cache_path}/*"
  end

  # CentOS��Apache�̍ċN���R�}���h�Q�B�s�K�v�Ȃ�폜�B
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

