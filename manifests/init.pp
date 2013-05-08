# Class: phpbuild
#
# This module manages the installing of php-build.
#
# Parameters:
#
# Actions:
#
# Requires:
#   puppetlabs/git
# Sample Usage:
#  class { 'phpbuild': }

class phpbuild {
  include git

  $phpbuildDir = '/home/vagrant/.phpbuild'
  $phpbuildTmp = '/tmp/phpbuild'
  $phpbuildRepo = 'git://github.com/CHH/php-build.git'

  case $operatingsystem {
    centos, redhat: {
      fail("CentOS or RedHat are not supported yet")
    }
    debian, ubuntu: {
      exec { "apt-get update":
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
      }

      $dependencies = [ "lsof", "iptables", "curl", "wget", "rsync", "libldap-2.4.2", "libldap2-dev", "libcurl4-openssl-dev", "mysql-client", "libmysqlclient-dev", "postgresql-client", "libpq-dev", "libssl-dev", "libxml2-dev", "libxslt1-dev", "libxslt-dev", "zlib1g-dev", "libssl0.9.8", "libbz2-dev", "libc-client2007e-dev", "libcurl4-gnutls-dev", "libfreetype6-dev", "libgmp3-dev", "libjpeg8-dev", "libmcrypt-dev", "libpng12-dev", "libt1-dev", "libmhash-dev", "libexpat1-dev", "libicu-dev", "libtidy-dev", "re2c", "lemon", "libstdc++6" ]

      package { $dependencies:
        ensure  => 'installed',
        require => Exec['apt-get update']
      } -> Exec["clone ${phpbuildRepo}"]

      file { "/usr/lib/${hardwaremodel}-linux-gnu/libpng.so":
        ensure  => 'link',
        target  => '/usr/lib/libpng.so',
        require => Package[$dependencies]
      } -> Exec["clone ${phpbuildRepo}"]

      if $operatingsystemrelease >= 12.04 {
        file { "/usr/lib/${hardwaremodel}-linux-gnu/libmysqlclient_r.so":
          ensure  => 'link',
          target  => '/usr/lib/libmysqlclient_r.so',
          require => Package[$dependencies]
        } -> Exec["clone ${phpbuildRepo}"]
      }

      if $operatingsystemrelease  >= 11.10 {
        package { 'libltdl-dev':
          ensure  => 'installed',
          require => Package[$dependencies]
        } -> Exec["clone ${phpbuildRepo}"]

        # on 11.10+, we also have to symlink libjpeg and a bunch of other libraries
        # because of the 32-bit/64-bit library directory separation. MK.
        file { "/usr/lib/${hardwaremodel}-linux-gnu/libjpeg.so":
          ensure  => 'link',
          target  => '/usr/lib/libjpeg.so',
          require => Package[$dependencies]
        } -> Exec["clone ${phpbuildRepo}"]

        /* file { "/usr/lib/${hardwaremodel}-linux-gnu//usr/lib/libstdc++.so.6":
          ensure  => 'link',
          target  => '/usr/lib/libstdc++.so.6',
          require => Package[$dependencies]
        } -> Exec["clone ${phpbuildRepo}"] */
      }
    }
    default: { fail("Unrecognized operating system for phpbuild") }
  }

  exec { "clone ${phpbuildRepo}":
    path    => '/usr/bin:/usr/sbin:/bin',
    command => "git clone ${phpbuildRepo} ${phpbuildTmp}",
    creates => "${phpbuildTmp}/.git",
    require => Package['git-core'],
  }

  exec { 'install phpbuild through bash script':
    path        => '/usr/bin:/usr/sbin:/bin',
    command     => "${phpbuildTmp}/install.sh",
    environment => "PREFIX=${phpbuildDir}",
    creates     => $phpbuildDir,
    user        => 'vagrant',
    require     => Exec["clone ${phpbuildRepo}"]
  }

  file { "${phpbuildDir}/share/php-build/default_configure_options":
    path    => "${phpbuildDir}/share/php-build/default_configure_options",
    owner   => 'vagrant',
    require => Exec['install phpbuild through bash script'],
    content => template('phpbuild/default_configure_options.erb'),
  }

  file { '/etc/profile.d/phpbuild.sh':
    path    => '/etc/profile.d/phpbuild.sh',
    require => Exec['install phpbuild through bash script'],
    content => template('phpbuild/phpbuild.sh.erb'),
  }
}
