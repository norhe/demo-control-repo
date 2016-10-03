class profile::puppet::consoleusers {
  rbac_user { 'deploy':
    ensure       => 'present',
    name         => 'deploy',
    display_name => 'deployment user account',
    email        => 'ehron@puppet.com',
    password     => 'puppetlabs',
    roles        => [ 'Code Deployers' ],
  }
}
