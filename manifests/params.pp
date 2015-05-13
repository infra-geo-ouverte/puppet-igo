# params.pp

class igo::params {

  $usedByVagrant    = false

  $igoRootPath      = '/var/igo'

  $databaseName     = 'igo'
  $databaseUser     = 'igo'
  $databasePassword = 'password'
  $pgUser           = 'postgres'

  $appUser          = 'vagrant'
  $appGroup         = 'vagrant'

  $mapserverVersion = '6.4.1-2'
  $cphalconVersion  = 'v1.3.1'

  # TODO: File path change depends on OS.
  $pgsqlScriptPath  = '/usr/share/postgresql/9.3/contrib/postgis-2.1'
  $srcPath          = '/usr/src'

  # TODO: Change to official librairie git depot when it will be available.
  $librairieGitRepo = 'https://gitlab.forge.gouv.qc.ca/simon.tremblay/librairie.git'

  $igoGitRepo = 'https://github.com/infra-geo-ouverte/igo.git'
}
