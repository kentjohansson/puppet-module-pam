# == Class: pam
#
# This module manages bits around PAM.
#
class pam (
  $allowed_users                 = 'root',
  $package_name                  = undef,
  $pam_conf_file                 = '/etc/pam.conf',
  $pam_d_login_oracle_options    = 'UNSET',
  $pam_d_login_path              = '/etc/pam.d/login',
  $pam_d_login_owner             = 'root',
  $pam_d_login_group             = 'root',
  $pam_d_login_mode              = '0644',
  $pam_d_login_template          = undef,
  $pam_d_sshd_path               = '/etc/pam.d/sshd',
  $pam_d_sshd_owner              = 'root',
  $pam_d_sshd_group              = 'root',
  $pam_d_sshd_mode               = '0644',
  $pam_d_sshd_template           = undef,
  $pam_auth_lines                = undef,
  $pam_account_lines             = undef,
  $pam_password_lines            = undef,
  $pam_session_lines             = undef,
  $system_auth_file              = '/etc/pam.d/system-auth',
  $system_auth_ac_file           = '/etc/pam.d/system-auth-ac',
  $system_auth_ac_auth_lines     = undef,
  $system_auth_ac_account_lines  = undef,
  $system_auth_ac_password_lines = undef,
  $system_auth_ac_session_lines  = undef,
) {

  include nsswitch

  case $::osfamily {
    'redhat': {
      case $::lsbmajdistrelease {
        '5': {
          $default_pam_d_login_template = 'pam/login.el5.erb'
          $default_pam_d_sshd_template  = 'pam/sshd.el5.erb'
          $default_package_name         = [ 'pam',
                                            'util-linux' ]

          $default_pam_auth_lines = [ 'auth        required      pam_env.so',
                                      'auth        sufficient    pam_unix.so nullok try_first_pass',
                                      'auth        requisite     pam_succeed_if.so uid >= 500 quiet',
                                      'auth        required      pam_deny.so']

          $default_pam_account_lines = [ 'account     required      pam_unix.so',
                                          'account     sufficient    pam_succeed_if.so uid < 500 quiet',
                                          'account     required      pam_permit.so']

          $default_pam_password_lines = [ 'password    requisite     pam_cracklib.so try_first_pass retry=3',
                                          'password    sufficient    pam_unix.so md5 shadow nullok try_first_pass use_authtok',
                                          'password    required      pam_deny.so']

          $default_pam_session_lines = [ 'session     optional      pam_keyinit.so revoke',
                                          'session     required      pam_limits.so',
                                          'session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid',
                                          'session     required      pam_unix.so']
        }
        '6': {
          $default_pam_d_login_template = 'pam/login.el6.erb'
          $default_pam_d_sshd_template  = 'pam/sshd.el6.erb'
          $default_package_name         = 'pam'

          $default_pam_auth_lines = [ 'auth        required      pam_env.so',
                                      'auth        sufficient    pam_fprintd.so',
                                      'auth        sufficient    pam_unix.so nullok try_first_pass',
                                      'auth        requisite     pam_succeed_if.so uid >= 500 quiet',
                                      'auth        required      pam_deny.so']

          $default_pam_account_lines = [ 'account     required      pam_unix.so',
                                          'account     sufficient    pam_localuser.so',
                                          'account     sufficient    pam_succeed_if.so uid < 500 quiet',
                                          'account     required      pam_permit.so']

          $default_pam_password_lines = [ 'password    requisite     pam_cracklib.so try_first_pass retry=3 type=',
                                          'password    sufficient    pam_unix.so md5 shadow nullok try_first_pass use_authtok',
                                          'password    required      pam_deny.so']

          $default_pam_session_lines = [ 'session     optional      pam_keyinit.so revoke',
                                          'session     required      pam_limits.so',
                                          'session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid',
                                          'session     required      pam_unix.so']
        }
        default: {
          fail("Pam is only supported on EL 5 and 6. Your lsbmajdistrelease is identified as <${::lsbmajdistrelease}>.")
        }
      }
    }
    'solaris': {
      case $::kernelrelease {
        '5.10': {
          $default_pam_auth_lines = ['login   auth requisite          pam_authtok_get.so.1',
                                      'login   auth required           pam_dhkeys.so.1',
                                      'login   auth required           pam_unix_cred.so.1',
                                      'login   auth required           pam_unix_auth.so.1',
                                      'login   auth required           pam_dial_auth.so.1',
                                      'passwd  auth required           pam_passwd_auth.so.1',
                                      'other   auth requisite          pam_authtok_get.so.1',
                                      'other   auth required           pam_dhkeys.so.1',
                                      'other   auth required           pam_unix_cred.so.1',
                                      'other   auth required           pam_unix_auth.so.1']

          $default_pam_account_lines = ['other   account requisite       pam_roles.so.1',
                                        'other   account required        pam_unix_account.so.1']

          $default_pam_password_lines = ['other   password required       pam_dhkeys.so.1',
                                          'other   password requisite      pam_authtok_get.so.1',
                                          'other   password requisite      pam_authtok_check.so.1',
                                          'other   password required       pam_authtok_store.so.1']

          $default_pam_session_lines = ['other   session required        pam_unix_session.so.1']
        }
        default: {
          fail("Pam is only supported on Solaris 10. Your kernelrelease is identified as <${::kernelrelease}>.")
        }
      }
    }
    default: {
      fail("Pam is only supported on RedHat and Solaris osfamilies. Your osfamily is identified as <${::osfamily}>.")
    }
  }

  if $package_name == undef {
    $my_package_name = $default_package_name
  } else {
    $my_package_name = $package_name
  }

  if $pam_d_login_template == undef {
    $my_pam_d_login_template = $default_pam_d_login_template
  } else {
    $my_pam_d_login_template = $pam_d_login_template
  }

  if $pam_d_sshd_template == undef {
    $my_pam_d_sshd_template = $default_pam_d_sshd_template
  } else {
    $my_pam_d_sshd_template = $pam_d_sshd_template
  }

  if $pam_auth_lines == undef {
    if $system_auth_ac_auth_lines == undef {
      $my_pam_auth_lines = $default_pam_auth_lines
    } else {
      $my_pam_auth_lines = $system_auth_ac_auth_lines
      notify { 'Deprecation notice: `$system_auth_ac_auth_lines` has been deprecated in `pam` class and will be removed in a future version. Use $pam_auth_lines instead.': }
    }
  } else {
    $my_pam_auth_lines = $pam_auth_lines
  }

  if $pam_account_lines == undef {
    if $system_auth_ac_account_lines == undef {
      $my_pam_account_lines = $default_pam_account_lines
    } else {
      $my_pam_account_lines = $system_auth_ac_account_lines
      notify { 'Deprecation notice: `$system_auth_ac_account_lines` has been deprecated in `pam` class and will be removed in a future version. Use $pam_account_lines instead.': }
    }
  } else {
    $my_pam_account_lines = $pam_account_lines
  }

  if $pam_password_lines == undef {
    if $system_auth_ac_password_lines == undef {
      $my_pam_password_lines = $default_pam_password_lines
    } else {
      $my_pam_password_lines = $system_auth_ac_password_lines
      notify { 'Deprecation notice: `$system_auth_ac_password_lines` has been deprecated in `pam` class and will be removed in a future version. Use $pam_password_lines instead.': }
    }
  } else {
    $my_pam_password_lines = $pam_password_lines
  }

  if $pam_session_lines == undef {
    if $system_auth_ac_session_lines == undef {
      $my_pam_session_lines = $default_pam_session_lines
    } else {
      $my_pam_session_lines = $system_auth_ac_session_lines
      notify { 'Deprecation notice: `$system_auth_ac_session_lines` has been deprecated in `pam` class and will be removed in a future version. Use $pam_session_lines instead.': }
    }
  } else {
    $my_pam_session_lines = $pam_session_lines
  }

  case $::osfamily {
    'redhat': {

      include pam::accesslogin
      include pam::limits

      package { 'pam_package':
        ensure => installed,
        name   => $my_package_name,
      }

      file { 'pam_d_login':
        ensure  => file,
        path    => $pam_d_login_path,
        content => template($my_pam_d_login_template),
        owner   => $pam_d_login_owner,
        group   => $pam_d_login_group,
        mode    => $pam_d_login_mode,
      }

      file { 'pam_d_sshd':
        ensure  => file,
        path    => $pam_d_sshd_path,
        content => template($my_pam_d_sshd_template),
        owner   => $pam_d_sshd_owner,
        group   => $pam_d_sshd_group,
        mode    => $pam_d_sshd_mode,
      }

      file { 'pam_system_auth_ac':
        ensure  => file,
        path    => $system_auth_ac_file,
        content => template('pam/system-auth-ac.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['pam_package'],
      }

      file { 'pam_system_auth':
        ensure  => symlink,
        path    => $system_auth_file,
        target  => $system_auth_ac_file,
        owner   => 'root',
        group   => 'root',
        require => Package['pam_package'],
      }
    }

    'solaris': {
      file { 'pam_conf':
        ensure  => file,
        path    => $pam_conf_file,
        owner   => 'root',
        group   => 'sys',
        mode    => '0644',
        content => template('pam/pam.conf.erb'),
      }
    }
    default: {
      fail("Pam is only supported on RedHat and Solaris osfamilies. Your osfamily is identified as <${::osfamily}>.")
    }
  }
}
