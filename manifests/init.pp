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
  $appGroup         = $::igo::params::appGroup,
  $mapserverVersion = $::igo::params::mapserVerversion,
  $cphalconVersion  = $::igo::params::cphalconVersion,
  $pgsqlScriptPath  = $::igo::params::pgsqlScriptPath,
  $phpiniPath       = $::igo::params::phpiniPath,
  $gitRepo          = $::igo::params::gitRepo,
  $pgUser           = $::igo::params::pgUser

) inherits ::igo::params {

  $igoAppPath = "${igoRootPath}/igo"
  $execPath   = [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ]

  file { "$igoAppPath":
    ensure  => 'link',
    target  => '/vagrant',
    force   => true,
    require => File[$igoRootPath]
  }
  file { "$igoRootPath":
    ensure => 'directory',
    force  => true,
  }
  class { '::igo::apache':
    igoRootPath => $igoRootPath,
    igoAppPath  => $igoAppPath,
    appUser     => $appUser,
    appGroup    => $appGroup
  }
  class { 'php': 
  }
  class { 'php::dev':
  }
  class { 'php::extension::curl':
  }
  class { 'php::extension::intl':
  }
  class { 'php::extension::mapscript':
  }
  class { 'php::extension::pgsql':
  }
  # TODO: check for other distribution names
  package { [ 'cgi-mapserver', 'mapserver-bin' ]:
    ensure => $mapserverVersion,
  }
  package { [ 'gdal-bin', 'gcc', 'make', 'libpcre3-dev', 'git' ]:
    ensure => present,
  }
  class { 'postgresql::server': 
  }
  class { 'postgresql::server::postgis':
  }
  postgresql::server::db { "$databaseName":
    user     => $databaseUser,
    password => $databasePassword,
  }
  postgresql::server::extension { 'plpgsql':
    database => $databaseName,
    ensure   => present,
  }
  exec { 'psql-postgis':
    command => "psql -d ${databaseName} -f ${pgsqlScriptPath}/postgis.sql",
    path    => $execPath,
    user    => $pgUser,
    require => Postgresql::Server::Extension['plpgsql'],
  }
  exec { 'psql-postgis_comments':
    command => "psql -d ${databaseName} -f ${pgsqlScriptPath}/postgis_comments.sql",
    path    => $execPath,
    user    => $pgUser,
    require => Exec['psql-postgis'],
  }
  exec { "psql-spatial_ref_sys":
    command => "psql -d ${databaseName} -f ${pgsqlScriptPath}/spatial_ref_sys.sql",
    path    => $execPath,
    user    => $pgUser,
    require => Exec['psql-postgis_comments'],
  }
  vcsrepo { "${srcPath}/cphalcon":
    ensure   => present,
    provider => git,
    source   => 'https://github.com/phalcon/cphalcon.git',
    revision => "phalcon-${cphalconVersion}",
    require  => Package['git'],
  }
  exec { 'installAndBuild-cphalcon':
    command => "./install",
    cwd     => "${srcPath}/cphalcon/build",
    path    => $execPath,
    require => [
      Vcsrepo["${srcPath}/cphalcon"],
      Class['php::dev'],
    ],
  }
  # FIXME: use php class to do this?
  file { "${phpiniPath}/30-phalcon.ini":
    content => 'extension=phalcon.so',
    require => [
      Class['php'],
      Class['apache'],
      Exec['installAndBuild-cphalcon'],
    ],
    notify  => Class['apache::service'],
  }
  vcsrepo { "${igoRootPath}/librairie":
    ensure   => present,
    provider => git,
    source   => $gitRepo,
    depth    => 1,
    require  => [
      Package['git'],
      Class['apache'],
      File[$igoRootPath],
    ],
  }
  # FIXME: what creates subdirs interfaces/navigateur/app, pilotage, config?
  file { "${igoAppPath}/interfaces/navigateur/app/cache":
    owner   => $appUser,
    group   => $appGroup,
    mode    => '0775',
    require => File["$igoAppPath"],
  }
  file { "${igoAppPath}/pilotage/app/cache":
    owner   => $appUser,
    group   => $appGroup,
    mode    => '0775',
    require => File["$igoAppPath"],
  }
  file { "${igoAppPath}/config/config.php":
    owner   => $appUser,
    group   => $appGroup,
    content => template("igo/config.php.erb"),
    require => File["$igoAppPath"],
  }
}
