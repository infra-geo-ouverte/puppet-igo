# params.pp

class igo::params {

  $igoRootPath      = '/var/igoroot'
  $databaseName     = 'igo'
  $databaseUser     = 'igo'
  $databasePassword = 'password'
  $appUser          = 'vagrant'
  $appGroup         = 'vagrant'
}
