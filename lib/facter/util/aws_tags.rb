require 'rubygems'
require 'aws-sdk'
require 'net/http'
require 'timeout'

module Facter::Util::AWSTags

  # Here we need to get server.id
  INSTANCE_HOST = '169.254.169.254'
  INSTANCE_ID_URL = '/latest/meta-data/instance-id'
  INSTANCE_REGION_URL = '/latest/meta-data/placement/availability-zone'

  def self.get_tags

    Timeout::timeout(30) {
      httpcall = Net::HTTP.new(INSTANCE_HOST)

      resp = httpcall.get(INSTANCE_ID_URL)
      instance_id = resp.body

      resp = httpcall.get(INSTANCE_REGION_URL)
      region = resp.body
    }

    # Cut out availability zone marker.
    # For example if region == "us-east-1c" after cutting out it will be
    # "us-east-1"

    region = region[0..-2]

    # First we configure AWS sdk from amazon, region is
    # required if your instances are in other zone than the
    # gem's default one (us-east-1).

    AWS.config(
        :credential_provider => AWS::Core::CredentialProviders::EC2Provider.new,
        :region => region)

    tags = AWS.ec2.instances[instance_id].tags.to_h

    # tags is a hash so create a fact for each
    tags.each_pair do | key, value |
      symbol = "ec2_tag_#{key.gsub(/\-|\//, '_')}".to_sym
      Facter.add(symbol) { setcode { value } }
    end
  end

end
