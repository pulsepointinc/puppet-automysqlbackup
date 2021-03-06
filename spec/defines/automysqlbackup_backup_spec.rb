require 'spec_helper'

describe 'automysqlbackup::backup' do
  let :default_params do
    {
      :cron_script         => false,
      :backup_dir          => '/backup',
      :etc_dir             => '/usr/local/etc'
    }
  end
  context 'on supported operating systems' do
    ['Debian', 'RedHat'].each do |osfamily|

      describe "with all params on defaults #{osfamily}" do
        let(:title) { 'db1' }
        let(:params) {{ }}
        let(:facts) {{ :osfamily => osfamily }}
        let(:pre_condition) { 'include automysqlbackup' }

        it 'should contain the automysqlbackup db config file' do
          should contain_file('/etc/automysqlbackup/db1.conf').with({
            'ensure' => 'file',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0650',
          })
        end
        it 'should create the cron job' do
          should contain_file('/etc/cron.daily/db1-automysqlbackup').with({
            'ensure' => 'file',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0755',
          })
        end
        it 'should create the backup destination' do
          should contain_file('/var/backup/db1').with({
            'ensure' => 'directory',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0755',
          })
        end
      end
      describe "with dir params changed and cron disabled" do
        let(:title) { 'db1' }
        let :params do default_params end
        let(:facts) {{ :osfamily => osfamily }}
        let(:pre_condition) { 'include automysqlbackup' }
        it 'should contain the automysqlbackup db config file' do
          should contain_file('/usr/local/etc/db1.conf').with({
            'ensure' => 'file',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0650',
          })
        end
        it 'should create the backup destination' do
          should contain_file('/backup/db1').with({
            'ensure' => 'directory',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0755',
          })
        end
        it 'should not create cron job' do
          should_not contain_file('/etc/cron.daily/db1-automysqlbackup')
        end
      end
      describe "with amb class using non-default etc dir" do
        let(:title) { 'db1' }
        let(:params) {{ }}
        let(:facts) {{ :osfamily => osfamily }}
        let(:pre_condition) { 'class { "automysqlbackup": etc_dir => "/usr/local/etc/amb", } ' }
        it 'should create the config file' do
          should contain_file('/usr/local/etc/amb/db1.conf').with({
            'ensure' => 'file',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0650',
          })
        end
      end
      describe "with amb class using non-default backup dir" do
        let(:title) { 'db1' }
        let(:params) {{ }}
        let(:facts) {{ :osfamily => osfamily }}
        let(:pre_condition) { 'class { "automysqlbackup": backup_dir => "/amb-backups", } ' }
        it 'should create the config file' do
          should contain_file('/amb-backups/db1').with({
            'ensure' => 'directory',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0755',
          })
        end
      end
      describe "with string for array param" do
        let(:title) { 'db1' }
        let(:params) {{ :db_exclude => "stringval" }}
        let(:facts) {{ :osfamily => osfamily }}
        let(:pre_condition) { 'include automysqlbackup' }
        it 'should throw an error' do
          expect { should contain_file('/etc/automysqlbackup/db1.conf') }.to raise_error(Puppet::Error, /is not an Array/)
        end
      end
    end
  end
  describe 'config template items' do
    let(:facts) {{
        :osfamily => 'Debian',
        :operatingsystemrelease => '6',
    }}
    let(:title) { 'db1' }
    describe 'inheriting basic params' do
      let :params do default_params end
    end
    # All match and notmatch should be a list of regexs and exact match strings
    context ".conf content" do
      [
        {
          :title => 'should contain backup_dir',
          :attr => 'backup_dir',
          :value => '/var/backup',
          :match => [/CONFIG_backup_dir='\/var\/backup\/db1'/],
        },
        {
          :title => 'should contain mysql_dump_username',
          :attr => 'mysql_dump_username',
          :value => 'mysqlroot',
          :match => [/CONFIG_mysql_dump_username='mysqlroot'/],
        },
        {
          :title => 'should contain mysql_dump_password',
          :attr => 'mysql_dump_password',
          :value => 'mysqlpass',
          :match => [/CONFIG_mysql_dump_password='mysqlpass'/],
        },
        {
          :title => 'should contain mysql_dump_host',
          :attr => 'mysql_dump_host',
          :value => '192.168.1.1',
          :match => [/CONFIG_mysql_dump_host='192.168.1.1'/],
        },
        {
          :title => 'should contain mysql_dump_port',
          :attr => 'mysql_dump_port',
          :value => '33306',
          :match => [/CONFIG_mysql_dump_port='33306'/],
        },
        {
          :title => 'should contain multicore',
          :attr => 'multicore',
          :value => 'yes',
          :match => [/CONFIG_multicore='yes'/],
        },
        {
          :title => 'should contain multicore_threads',
          :attr => 'multicore_threads',
          :value => '3',
          :match => [/CONFIG_multicore_threads='3'/],
        },
        {
          :title => 'should contain db_names',
          :attr => 'db_names',
          :value => ['test','prod_db'],
          :match => [/CONFIG_db_names=\( 'test' 'prod_db' \)/],
        },
        {
          :title => 'should contain db_month_names',
          :attr => 'db_month_names',
          :value => ['prod_db','prod_db2'],
          :match => [/CONFIG_db_month_names=\( 'prod_db' 'prod_db2' \)/],
        },
        {
          :title => 'should contain db_exclude',
          :attr => 'db_exclude',
          :value => ['dev_db','stage_db'],
          :match => [/CONFIG_db_exclude=\( 'dev_db' 'stage_db' \)/],
        },
        {
          :title => 'should contain table_exclude',
          :attr => 'table_exclude',
          :value => ['sessions','temp'],
          :match => [/CONFIG_table_exclude=\( 'sessions' 'temp' \)/],
        },
        {
          :title => 'should contain do_monthly',
          :attr => 'do_monthly',
          :value => '05',
          :match => [/CONFIG_do_monthly='05'/],
        },
        {
          :title => 'should contain do_weekly',
          :attr => 'do_weekly',
          :value => '2',
          :match => [/CONFIG_do_weekly='2'/],
        },
        {
          :title => 'should contain rotation_daily',
          :attr => 'rotation_daily',
          :value => '4',
          :match => [/CONFIG_rotation_daily='4'/],
        },
        {
          :title => 'should contain rotation_weekly',
          :attr => 'rotation_weekly',
          :value => '45',
          :match => [/CONFIG_rotation_weekly='45'/],
        },
        {
          :title => 'should contain rotation_monthly',
          :attr => 'rotation_monthly',
          :value => '230',
          :match => [/CONFIG_rotation_monthly='230'/],
        },
        {
          :title => 'should contain mysql_dump_commcomp',
          :attr => 'mysql_dump_commcomp',
          :value => 'value',
          :match => [/CONFIG_mysql_dump_commcomp='value'/],
        },
        {
          :title => 'should contain mysql_dump_usessl',
          :attr => 'mysql_dump_usessl',
          :value => 'yes',
          :match => [/CONFIG_mysql_dump_usessl='yes'/],
        },
        {
          :title => 'should contain mysql_dump_socket',
          :attr => 'mysql_dump_socket',
          :value => 'none.sock',
          :match => [/CONFIG_mysql_dump_socket='none.sock'/],
        },
        {
          :title => 'should contain mysql_dump_max_allowed_packet',
          :attr => 'mysql_dump_max_allowed_packet',
          :value => '400',
          :match => [/CONFIG_mysql_dump_max_allowed_packet='400'/],
        },
        {
          :title => 'should contain mysql_dump_buffer_size',
          :attr => 'mysql_dump_buffer_size',
          :value => '300',
          :match => [/CONFIG_mysql_dump_buffer_size='300'/],
        },
        {
          :title => 'should contain mysql_dump_single_transaction',
          :attr => 'mysql_dump_single_transaction',
          :value => 'yes',
          :match => [/CONFIG_mysql_dump_single_transaction='yes'/],
        },
        {
          :title => 'should contain mysql_dump_master_data',
          :attr => 'mysql_dump_master_data',
          :value => '1',
          :match => [/CONFIG_mysql_dump_master_data='1'/],
        },
        {
          :title => 'should contain mysql_dump_full_schema',
          :attr => 'mysql_dump_full_schema',
          :value => 'yes',
          :match => [/CONFIG_mysql_dump_full_schema='yes'/],
        },
        {
          :title => 'should contain mysql_dump_dbstatus',
          :attr => 'mysql_dump_dbstatus',
          :value => 'yes',
          :match => [/CONFIG_mysql_dump_dbstatus='yes'/],
        },
        {
          :title => 'should contain mysql_dump_create_database',
          :attr => 'mysql_dump_create_database',
          :value => 'yes',
          :match => [/CONFIG_mysql_dump_create_database='yes'/],
        },
        {
          :title => 'should contain mysql_dump_use_separate_dirs',
          :attr => 'mysql_dump_use_separate_dirs',
          :value => 'yes',
          :match => [/CONFIG_mysql_dump_use_separate_dirs='yes'/],
        },
        {
          :title => 'should contain mysql_dump_compression',
          :attr => 'mysql_dump_compression',
          :value => 'bzip2',
          :match => [/CONFIG_mysql_dump_compression='bzip2'/],
        },
        {
          :title => 'should contain mysql_dump_latest',
          :attr => 'mysql_dump_latest',
          :value => 'yes',
          :match => [/CONFIG_mysql_dump_latest='yes'/],
        },
        {
          :title => 'should contain mysql_dump_latest_clean_filenames',
          :attr => 'mysql_dump_latest_clean_filenames',
          :value => 'yes',
          :match => [/CONFIG_mysql_dump_latest_clean_filenames='yes'/],
        },
        {
          :title => 'should contain mysql_dump_differential',
          :attr => 'mysql_dump_differential',
          :value => 'yes',
          :match => [/CONFIG_mysql_dump_differential='yes'/],
        },
        {
          :title => 'should contain mailcontent',
          :attr => 'mailcontent',
          :value => 'nonegiven',
          :match => [/CONFIG_mailcontent='nonegiven'/],
        },
        {
          :title => 'should contain mail_maxattsize',
          :attr => 'mail_maxattsize',
          :value => '40',
          :match => [/CONFIG_mail_maxattsize='40'/],
        },
        {
          :title => 'should contain mail_splitandtar',
          :attr => 'mail_splitandtar',
          :value => 'no',
          :match => [/CONFIG_mail_splitandtar='no'/],
        },
        {
          :title => 'should contain mail_use_uuencoded_attachments',
          :attr => 'mail_use_uuencoded_attachments',
          :value => 'no',
          :match => [/CONFIG_mail_use_uuencoded_attachments='no'/],
        },
        {
          :title => 'should contain mail_address',
          :attr => 'mail_address',
          :value => 'root@example.com',
          :match => [/CONFIG_mail_address='root@example.com'/],
        },
        {
          :title => 'should contain encrypt',
          :attr => 'encrypt',
          :value => 'yes',
          :match => [/CONFIG_encrypt='yes'/],
        },
        {
          :title => 'should contain encrypt_password',
          :attr => 'encrypt_password',
          :value => 'supersecret',
          :match => [/CONFIG_encrypt_password='supersecret'/],
        },
        {
          :title => 'should contain backup_local_files',
          :attr => 'backup_local_files',
          :value => ['/etc/motd','/etc/hosts'],
          :match => [/CONFIG_backup_local_files=\( '\/etc\/motd' '\/etc\/hosts' \)/],
        },
        {
          :title => 'should contain prebackup',
          :attr => 'prebackup',
          :value => '/usr/local/bin/myscript',
          :match => [/CONFIG_prebackup='\/usr\/local\/bin\/myscript'/],
        },
        {
          :title => 'should contain postbackup',
          :attr => 'postbackup',
          :value => '/usr/local/bin/myotherscript',
          :match => [/CONFIG_postbackup='\/usr\/local\/bin\/myotherscript'/],
        },
        {
          :title => 'should contain umask',
          :attr => 'umask',
          :value => '0020',
          :match => [/CONFIG_umask='0020'/],
        },
        {
          :title => 'should contain dryrun',
          :attr => 'dryrun',
          :value => 'no',
          :match => [/CONFIG_dryrun='no'/],
        }
      ].each do |param|
        describe "when #{param[:attr]} is #{param[:value]}" do
          let :params do default_params.merge({ param[:attr].to_sym => param[:value] }) end
          it { should contain_file("#{params[:etc_dir]}/#{title}.conf").with_mode('0650') }
          if param[:match]
            it "#{param[:title]}: matches" do
              param[:match].each do |match|
                should contain_file("#{params[:etc_dir]}/#{title}.conf").with_content( match )
              end
            end
          end
        end
      end
    end
  end
end
