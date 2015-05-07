#class igo::apache

class igo::apache(
  $igoRootPath,
  $igoAppPath,
  $appUser,
  $appGroup
) {
  include apache::mod::rewrite
  include apache::mod::cgi

  class { '::apache':
    mpm_module => 'prefork',
    default_vhost => false,
    user         => $appUser,
    group        => $appGroup
  }
  class { '::apache::mod::php': }

  apache::vhost { 'igo':
    vhost_name       => '*',
    port             => '80',
    docroot          => $igoRootPath,
    docroot_owner    => $appUser,
    docroot_group    => $appGroup,
    aliases => [
      { alias            => '/pilotage',
        path             => "${igoAppPath}/pilotage/",
      },
      { alias            => '/navigateur/',
        path             => "${igoAppPath}/interfaces/navigateur/",
      },
      { alias            => '/api/',
        path             => "${igoAppPath}/interfaces/navigateur/api/",
      }
    ],
    directories      =>
    [
      {
        path      => "${igoAppPath}/pilotage/",
        provider  => 'directory',
        php_value => 'max_input_vars 2000',
        rewrites => [
                      {
                        rewrite_rule => [ '^$ public/    [L]' ]
                      },
                      {
                        rewrite_rule => [ '(.*) public/$1 [L]' ]
                      }

                    ]
      },
      {
        path      => "${igoAppPath}/pilotage/public/",
        provider  => 'directory',
        add_default_charset => 'UTF-8',
        rewrites => [
                      {
                        rewrite_cond => [ '%{REQUEST_FILENAME} !-d' ]
                      },
                      {
                        rewrite_cond => [ '%{REQUEST_FILENAME} !-f' ]
                      },
                      {
                        rewrite_rule => [ '^(.*)$ index.php?_url=/$1 [QSA,L]' ]
                      }
                    ]
      },
      {
        path      => "${igoAppPath}/interfaces/navigateur/",
        provider  => 'directory',
        rewrites => [
                      {
                        rewrite_rule => [ '^$ public/    [L]' ]
                      },
                      {
                        rewrite_rule => [ '(.*) public/$1 [L]' ]
                      }
                    ]
      },
      {
        path      => "${igoAppPath}/interfaces/navigateur/public/",
        provider  => 'directory',
        add_default_charset => 'UTF-8',
        rewrites => [
                      {
                        rewrite_cond => [ '%{REQUEST_FILENAME} !-d' ]
                      },
                      {
                        rewrite_cond => [ '%{REQUEST_FILENAME} !-f' ]
                      },
                      {
                        rewrite_rule => [ '^(.*)$ index.php?_url=/$1 [QSA,L]' ]
                      }
                    ]
      },
      {
        path      => "${igoAppPath}/interfaces/navigateur/api/",
        provider  => 'directory',
        rewrites => [
                      {
                        rewrite_cond => [ '%{REQUEST_FILENAME} !-f' ]
                      },
                      {
                        rewrite_rule => [ '^(.*)$ index.php?_url=/$1 [QSA,L]' ]
                      }
                    ]
      },
    ],
  }
}
