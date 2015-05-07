# Class: igo
#
# This module manages installation and configuration of IGO project.
#
#
#
# Requires: see metadata.json
#
# Sample Usage:
#
# class { 'igo': }
#
class igo(
  $igoRootPath      = $::igo::params::igoRootPath,
  $databaseName     = $::igo::params::databaseName,
  $databaseUser     = $::igo::params::databaseUser,
  $databasePassword = $::igo::params::databasePassword,
  $appUser          = $::igo::params::appUser,
  $appGroup         = $::igo::params::appGroup
) inherits ::igo::params {

  # FIXME: File path change depends on OS.
  $pgsqlScriptPath = '/usr/share/postgresql/9.3/contrib/postgis-2.1'

  $igoAppPath = "${igoRootPath}/igo"

  class { '::igo::apache':
    igoRootPath => $igoRootPath,
    igoAppPath  => $igoAppPath,
    appUser     => $appUser,
    appGroup    => $appGroup
  }

  file { $igoAppPath:
    ensure  => 'link',
    target  => '/vagrant',
    force   => true,
    require => File[$igoRootPath]
  }

  file { $igoRootPath:
    ensure => 'directory',
    force  => true
  }

  package {'cgi-mapserver':
    ensure => '6.4.1-2'
  }

  package {'mapserver-bin':
    ensure => '6.4.1-2'
  }

  package {'gdal-bin': }

  package {'gcc': }
  package {'make': }
  package {'libpcre3-dev': }

  package {'git': }

  class { 'php': }
  class { 'php::dev': }

  class { 'php::extension::curl': }
  class { 'php::extension::intl': }
  class { 'php::extension::mapscript': }
  class { 'php::extension::pgsql': }

  class { 'postgresql::server': }

  class {'postgresql::server::postgis':}

  postgresql::server::db { $databaseName:
    user     => $databaseUser,
    password => $databasePassword,
  }

  postgresql::server::extension { 'plpgsql':
    database => $databaseName,
    ensure => present
  }

  exec { "psql-postgis":
    command => "psql -d ${databaseName} -f ${pgsqlScriptPath}/postgis.sql",
    path => "/usr/bin",
    user => 'postgres',
    require => Postgresql::Server::Extension['plpgsql']
  }

  exec { "psql-postgis_comments":
    command => "psql -d ${databaseName} -f ${pgsqlScriptPath}/postgis_comments.sql",
    path => "/usr/bin",
    user => 'postgres',
    require => Exec['psql-postgis']
  }

  exec { "psql-spatial_ref_sys":
    command => "psql -d ${databaseName} -f ${pgsqlScriptPath}/spatial_ref_sys.sql",
    path => "/usr/bin",
    user => 'postgres',
    require => Exec['psql-postgis_comments']
  }

  vcsrepo { '/var/tmp/cphalcon':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/phalcon/cphalcon.git',
    revision => 'phalcon-v1.3.1',
    require  => Package['git']
  }

  exec { 'installAndBuild-cphalcon':
    command => "./install",
    cwd => '/var/tmp/cphalcon/build',
    path => ['/usr/bin', '/bin'],
    require => [
                 Vcsrepo['/var/tmp/cphalcon'],
                 Class['php::dev']
               ]
  }

  # FIXME: File path change depends on OS.
  file { '/etc/php5/apache2/conf.d/30-phalcon.ini':
    content => 'extension=phalcon.so',
    require => [
                 Class['php'],
                 Class['apache'],
                 Exec['installAndBuild-cphalcon']
               ],
    notify => Class['apache::service']
  }

  # TODO: Change to official librairie git depot when it will be available.
  vcsrepo { "${igoRootPath}/librairie":
    ensure   => present,
    provider => git,
    source   => 'https://gitlab.forge.gouv.qc.ca/simon.tremblay/librairie.git',
    depth    => 1,
    require => [
                 Package['git'],
                 Class['apache'],
                 File[$igoRootPath]
               ]
  }

  file { "${igoAppPath}/interfaces/navigateur/app/cache":
    owner => $appUser,
    group => $appGroup,
    mode => '0775',
    require => File[$igoAppPath]
  }

  file { "${igoAppPath}/pilotage/app/cache":
    owner => $appUser,
    group => $appGroup,
    mode => '0775',
    require => File[$igoAppPath]
  }

  file {"${igoAppPath}/config/config.php":
    owner => $appUser,
    group => $appGroup,
    content => template("igo/config.php.erb"),
    require => File[$igoAppPath]
  }

}
