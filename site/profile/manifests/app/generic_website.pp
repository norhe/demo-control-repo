# Example cross platform generic website class
class profile::app::generic_website {
  if $::kernel == 'Windows' {

      $doc_root = 'C:\inetpub\wwwroot\generic_website'
      windowsfeature { 'IIS':
        feature_name => [
          'Web-Server',
          'Web-WebServer',
          'Web-Http-Redirect',
          'Web-Mgmt-Console',
          'Web-Mgmt-Tools'
        ]
      }

      iis::manage_site {'Default Web Site':
        ensure => absent,
      }

      iis::manage_app_pool {'generic_website':
        require => [
                    Windowsfeature['IIS'],
                    Iis::Manage_site['Default Web Site'],
                  ]
      }

      iis::manage_site { $::fqdn:
        site_path   => $doc_root,
        port        => '80',
        ip_address  => '*',
        app_pool    => 'generic_website',
        require     => [
                          Windowsfeature['IIS'],
                          Iis::Manage_app_pool['generic_website']
                        ]
      }

      staging::deploy { 'pl_generic_site.zip':
        source  => 'puppet:///modules/profile/pl_generic_site.zip',
        target  => $doc_root,
        require => Iis::Manage_site[$::fqdn],
        creates => "${doc_root}/index.html",
      }

  } elsif $::kernel == 'Linux' {

    if !defined(Package['unzip']) {
      package {'unzip': ensure => present, }
    }

    $doc_root = '/var/www/generic_website'
    class { 'apache':
        default_vhost => false,
    }

    file { $doc_root:
      ensure => directory,
      owner  => $::apache::user,
      group  => $::apache::group,
      mode   => '0755',
    }

    apache::vhost { $::fqdn:
      port    => '80',
      docroot => $doc_root,
      require => File[$doc_root],
    }

    staging::deploy { 'pl_generic_site.zip':
      source  => 'puppet:///modules/profile/pl_generic_site.zip',
      target  => $doc_root,
      require => Apache::Vhost[$::fqdn],
      creates => "${doc_root}/index.html",
    }

  }



}
