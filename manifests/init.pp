# == Class: automysqlbackup
#
# Puppet module to install AutoMySQLBackup for periodic MySQL backups.
#
# === Variables
#
# [bin_dir]
#   - Location for the automysqlbackup binary file
#
# [etc_dir]
#   - Location to store all configurations for AMB
#
# [backup_dir]
#   - Location to store backups generated by AMB
#
# [install_multicore]
#   - Boolean to install multicore compression support (assumes packages
#     available in repo). If RedHat family, these packages can be found in the
#     RPMforge repos
#
# [config]
#   - Takes a hash passed by Hiera to create backup resources
#
# [config_defaults]
#   - Takes a hash of defaults passed by Hiera to create resources
#
# === Examples
#
#  # Assume the defaults
#  include automysqlbackup
#
#  # With a custom backup directory
#  class { 'automysqlbackup':
#    backup_dir  => /mnt/backups,
#  }
#
# === Authors
#
# NextRevision <notarobot@nextrevision.net>
#
# === Copyright
#
# Copyright 2013 NextRevision, unless otherwise noted.

class automysqlbackup (
  $bin_dir           = $automysqlbackup::params::bin_dir,
  $etc_dir           = $automysqlbackup::params::etc_dir,
  $backup_dir        = $automysqlbackup::params::backup_dir,
  $install_multicore = undef,
  $config            = {},
  $config_defaults   = {},
) inherits automysqlbackup::params {

  # Create a subdirectory in /etc for config files
  file { $etc_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
  }

  # Create an example backup file, useful for reference
  file { "${etc_dir}/automysqlbackup.conf.example":
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0660',
    source => 'puppet:///modules/automysqlbackup/automysqlbackup.conf',
  }

  # Add files from the developer
  file { "${etc_dir}/AMB_README":
    ensure => file,
    source => 'puppet:///modules/automysqlbackup/AMB_README',
  }
  file { "${etc_dir}/AMB_LICENSE":
    ensure => file,
    source => 'puppet:///modules/automysqlbackup/AMB_LICENSE',
  }

  # Install the actual binary file
  file { "${bin_dir}/automysqlbackup":
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/automysqlbackup/automysqlbackup',
  }

  # Create the base backup directory
  file { $backup_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # If you'd like to keep your config in hiera and pass it to this class
  if !empty($config) {
    create_resources('automysqlbackup::backup', $config, $config_defaults)
  }

  # If using RedHat family, must have the RPMforge repo's enabled
  if $install_multicore {
    package { ['pigz', 'pbzip2']: ensure => installed }
  }

}
