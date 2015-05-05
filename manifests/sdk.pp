# Installs the AWS Ruby SDK
class aws::sdk {

  # If we're on Amazon we've got the ruby sdk in an rpm. Otherwise we'll get
  # it via gems.
  if $::operatingsystem == 'Amazon' {

    package { 'rubygem-aws-sdk':
        ensure => '1.26.0-1.0.amzn1',
    }

  } else {

    class { 'ruby':
      rubygems_update => false
    }

    package { 'nokogiri':
      ensure   => ['1.5.6'],
      provider => 'gem',
    } ->
    package { 'json':
      ensure   => ['1.4.6'],
      provider => 'gem',
    } ->
    package { 'uuidtools':
      ensure   => ['2.1.1'],
      provider => 'gem',
    } ->
    package { 'aws-sdk':
      ensure   => ['1.26.0'],
      provider => 'gem',
    }
    package { 'retriable':
      ensure   => ['2.0.2'],
      provider => 'gem',
    }

  }

}
