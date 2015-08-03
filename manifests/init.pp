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
class igo (

  $usedByVagrant    = $::igo::params::usedByVagrant,
  $igoRootPath      = $::igo::params::igoRootPath,
  $databaseName     = $::igo::params::databaseName,
  $databaseUser     = $::igo::params::databaseUser,
  $databasePassword = $::igo::params::databasePassword,
  $pgUser           = $::igo::params::pgUser,
  $appUser          = $::igo::params::appUser,
  $appGroup         = $::igo::params::appGroup,
  $mapserverVersion = $::igo::params::mapserVerversion,
  $igoGitRepo       = $::igo::params::igoGitRepo,
  $igoVersion       = $::igo::params::igoVersion,
  $librairieGitRepo = $::igo::params::librairieGitRepo,
  $librairieVersion = $::igo::params::librairieVersion,
  $cphalconGitRepo  = $::igo::params::cphalconGitRepo,
  $cphalconVersion  = $::igo::params::cphalconVersion,
  $pgsqlEtcPath     = $::igo::params::pgsqlEtcPath,
  $pgsqlScriptPath  = $::igo::params::pgsqlScriptPath,
  $srcPath          = $::igo::params::srcPath,
  $configTemplate   = $::igo::params::configTemplate,

) inherits ::igo::params {

  $igoAppPath = "${igoRootPath}/igo"
  $execPath   = [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ]

  package { 'git':
    ensure => present,
  }
  file { $igoRootPath:
    ensure => 'directory',
    owner  => $appUser,
    group  => $appGroup,
    mode   => '0775',
  }
  if $usedByVagrant == true {
    file { $igoAppPath:
      ensure  => 'link',
      target  => '/vagrant',
      force   => true,
      require => File[$igoRootPath]
    }
    $requiredIgoAppPath = File[$igoAppPath]
  } else {
    vcsrepo { $igoAppPath:
      ensure   => present,
      provider => git,
      source   => $igoGitRepo,
      revision => $igoVersion,
      require  => [
        Package['git'],
        File[$igoRootPath],
      ],
    }
    $requiredIgoAppPath = Vcsrepo[$igoAppPath]
  }
  vcsrepo { "${igoAppPath}/librairie":
    ensure   => present,
    provider => git,
    source   => $librairieGitRepo,
    depth    => 1,
    require  => [
      Package['git'],
      File[$igoRootPath],
    ],
  }
  file { "${igoAppPath}/interfaces/navigateur/app/cache":
    owner   => $appUser,
    group   => $appGroup,
    mode    => '0775',
    require => $requiredIgoAppPath,
  }
  file { "${igoAppPath}/pilotage/app/cache":
    owner   => $appUser,
    group   => $appGroup,
    mode    => '0775',
    require => $requiredIgoAppPath,
  }
  file { "${igoAppPath}/config/config.php":
    owner   => $appUser,
    group   => $appGroup,
    source  => "${igoAppPath}/config/config.exempleSimple.php",
    require => $requiredIgoAppPath,
  }
  class { '::igo::apache':
    igoRootPath => $igoRootPath,
    igoAppPath  => $igoAppPath,
    appUser     => $appUser,
    appGroup    => $appGroup
  }
  class { 'php':
  }
  class { 'php::devel':
  }
  php::module { 'curl':
  }
  php::module { 'intl':
  }
  php::module { 'mapscript':
  }
  php::module { 'pgsql':
  }
  # TODO: check for other distribution names
  package { [ 'cgi-mapserver', 'mapserver-bin' ]:
    ensure => $mapserverVersion,
  }
  package { [ 'gdal-bin', 'gcc', 'make', 'libpcre3-dev', ]:
    ensure => present,
  }
  vcsrepo { "${srcPath}/cphalcon":
    ensure   => present,
    provider => git,
    source   => 'https://github.com/phalcon/cphalcon.git',
    revision => "phalcon-${cphalconVersion}",
    require  => Package['git'],
  }
  exec { 'installAndBuild-cphalcon':
    command => './install',
    cwd     => "${srcPath}/cphalcon/build",
    path    => $execPath,
    creates => '/usr/lib/php5/20121212/phalcon.so',
    require => [
      Vcsrepo["${srcPath}/cphalcon"],
      Class['php::devel'],
    ],
  }
  php::ini { 'createPHPiniPhalcon':
    target  => '30-phalcon.ini',
    value   => 'extension=phalcon.so',
    require => Exec['installAndBuild-cphalcon'],
  }
  class { 'postgresql::server':
  }
  class { 'postgresql::server::postgis':
  }
  postgresql::server::db { $databaseName:
    user     => $databaseUser,
    password => $databasePassword,
  }
  postgresql::server::extension { 'plpgsql':
    ensure   => present,
    database => $databaseName,
  }
  exec { 'psql-postgis':
    command =>
      "psql -d ${databaseName} -f ${pgsqlScriptPath}/postgis.sql && \
       touch ${pgsqlEtcPath}/psql-postgis.done",
    path    => $execPath,
    user    => $pgUser,
    creates => "${pgsqlEtcPath}/psql-postgis.done",
    require => Postgresql::Server::Extension['plpgsql'],
  }
  exec { 'psql-postgis_comments':
    command =>
      "psql -d ${databaseName} -f ${pgsqlScriptPath}/postgis_comments.sql && \
       touch ${pgsqlEtcPath}/psql-postgis_comments.done",
    path    => $execPath,
    user    => $pgUser,
    creates => "${pgsqlEtcPath}/psql-postgis_comments.done",
    require => Exec['psql-postgis'],
  }
  exec { 'psql-spatial_ref_sys':
    command =>
      "psql -d ${databaseName} -f ${pgsqlScriptPath}/spatial_ref_sys.sql && \
       touch ${pgsqlEtcPath}/psql-spatial_ref_sys.done",
    path    => $execPath,
    user    => $pgUser,
    creates => "${pgsqlEtcPath}/psql-spatial_ref_sys.done",
    require => Exec['psql-postgis_comments'],
  }
}
