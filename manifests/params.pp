# params.pp

class igo::params {

  include ::postgresql::globals

  $usedByVagrant    = false

  $igoRootPath      = '/var/igo'

  $databaseName     = 'igo'
  $databaseUser     = 'igo'
  $databasePassword = 'password'
  $pgUser           = 'postgres'

  $appUser          = 'vagrant'
  $appGroup         = 'vagrant'

  $mapserverVersion = '6.4.1-2'

  $igoGitRepo       = 'https://github.com/infra-geo-ouverte/igo.git'
  $igoVersion       = 'master'
  
  $librairieGitRepo = 'https://github.com/infra-geo-ouverte/igo-lib.git'
  $librairieVersion = 'master'

  $cphalconGitRepo  = 'https://github.com/phalcon/cphalcon.git'
  $cphalconVersion  = 'v1.3.1'
  
  $pgsqlEtcPath     = "/etc/postgresql/${::postgresql::globals::default_version}"
  $pgsqlScriptPath  = "/usr/share/postgresql/${::postgresql::globals::default_version}/contrib/postgis-${::postgresql::globals::default_postgis_version}"
  $srcPath          = '/usr/src'
  
  $configTemplate   = 'igo/config.php.erb'

}
