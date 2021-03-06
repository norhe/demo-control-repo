class profile::app::plsample (
  String  $plsample_version     = "1.2",
  String  $tomcat_major_version = "7",
) {
  include profile::firewall

  case $tomcat_major_version {
    '6': {
           $tomcat_version = '6.0.44'
           $catalina_dir = "/opt/apache-tomcat6"
           $tomcat_other_versions = [ '7', '8']
         }
    '7': {
           $tomcat_version = '7.0.64' 
           $catalina_dir = "/opt/apache-tomcat7"
           $tomcat_other_versions = [ '6', '8']
         }
    '8': {
           $tomcat_version = '8.0.26' 
           $catalina_dir = "/opt/apache-tomcat8"
           $tomcat_other_versions = [ '6', '7']
         }
  }

  if $::kernel == 'Linux' {

    class { 'java':
      distribution => 'jre'
    }

    class { '::tomcat':
      catalina_home => $catalina_dir, 
    }

    firewall { '100 allow tomcat access':
      dport  => [8080],
      proto  => tcp,
      action => accept,
    }

    tomcat::instance{ "tomcat${tomcat_major_version}":
      install_from_source    => true,
      source_url             => "http://master.inf.puppetlabs.demo/tomcat/apache-tomcat-${tomcat_version}.tar.gz",
      source_strip_first_dir => true,
      catalina_base          => "${catalina_dir}",
      catalina_home          => "${catalina_dir}",
      before                 => Tomcat::War["plsample-${plsample_version}.war"],
    }

    tomcat::war { "plsample-${plsample_version}.war" :
      war_source    => "http://master.inf.puppetlabs.demo/tomcat/plsample-${plsample_version}.war",
      catalina_base => "${catalina_dir}",
      notify        => File["${catalina_dir}/webapps/plsample"],
    }

    file { "${catalina_dir}/webapps/plsample":
      ensure => 'link',
      target => "${catalina_dir}/webapps/plsample-${plsample_version}",
      notify => Tomcat::Service["plsample-tomcat${tomcat_major_version}"],
    }
    $tomcat_other_versions.each |String $version| {
      service {"tomcat-plsample-tomcat${version}":
        ensure       => stopped,
        status       => "ps aux | grep \'catalina.base=/opt/apache-tomcat${version}\' | grep -v grep",
        stop         => "su -s /bin/bash -c \'/opt/apache-tomcat${version}/bin/catalina.sh stop tomcat\'",
        before       => File["/opt/apache-tomcat${version}"],
      }
      file {"/opt/apache-tomcat${version}":
        ensure  => absent,
        force   => true,
        backup  => false,
        before  => Tomcat::Service["plsample-tomcat${tomcat_major_version}"],
      }
    }

    tomcat::service { "plsample-tomcat${tomcat_major_version}":
      catalina_base => "${catalina_dir}",
      catalina_home => "${catalina_dir}",
      service_name  => "plsample",
      subscribe     => Tomcat::War["plsample-${plsample_version}.war"],
    }
  }
  elsif $kernel == 'windows' {

    include windows_java

    windows_firewall::exception { 'Tomcat':
      ensure       => present,
      direction    => 'in',
      action       => 'Allow',
      enabled      => 'yes',
      protocol     => 'TCP',
      local_port   => '8080',
      display_name => 'Apache Tomcat Port',
      description  => 'Inbound rule for Tomcat',
    } 

    remote_file { "C:/apache-tomcat-${tomcat_version}.exe":
      ensure => present,
      source => "http://master.inf.puppetlabs.demo/tomcat/apache-tomcat-${tomcat_version}.exe",
      before => Package["Apache Tomcat ${tomcat_major_version}.0 Tomcat${tomcat_major_version} (remove only)"],
    }

    $tomcat_other_versions.each |String $version| {
      exec { "remove tomcat ${version}":
        command  => "\"C:/Program Files/Apache Software Foundation/Tomcat ${version}.0/Uninstall.exe\" /S -ServiceName=tomcat${version}",
        unless   => "cmd.exe /c if exist \"C:\\Program Files\\Apache Software Foundation\\Tomcat ${version}.0\\Uninstall.exe\" (exit /b 1)",
        path     => 'C:\windows\system32;C:\windows',
        before   => Package["Apache Tomcat ${tomcat_major_version}.0 Tomcat${tomcat_major_version} (remove only)"],
      }
    }

    package { "Apache Tomcat ${tomcat_major_version}.0 Tomcat${tomcat_major_version} (remove only)":
      ensure => present,
      source => "C:/apache-tomcat-${tomcat_version}.exe",
      install_options => ['/S'],
      require => Class['windows_java'],
    }

    service { "tomcat${tomcat_major_version}":
      ensure    => running,
      enable    => true,
      require   => Package["Apache Tomcat ${tomcat_major_version}.0 Tomcat${tomcat_major_version} (remove only)"],
    }

    remote_file { "C:/Program Files/Apache Software Foundation/Tomcat ${tomcat_major_version}.0/webapps/plsample-${plsample_version}.war":
      ensure  => latest,
      source  => "http://master.inf.puppetlabs.demo/tomcat/plsample-${plsample_version}.war",
      require => Service["tomcat${tomcat_major_version}"],
    }
  }
}
