require 'rubygems'
require 'aws-sdk'
require "net/http"
require 'retriable'
require 'yaml'

module Facter::Util::AWSTags

  # Here we need to get server.id
  INSTANCE_HOST = '169.254.169.254'
  INSTANCE_ID_URL = '/latest/meta-data/instance-id'
  INSTANCE_REGION_URL = '/latest/meta-data/placement/availability-zone'

  # File to store tags in, this should be cleared every reboot
  CACHE_FILE = '/tmp/puppet_aws_tags.cache'

  def self.get_tags
    cache = Hash.new

    # If the cache file exists and load it, otherwise fetch origin
    if File.exists?(CACHE_FILE)
      YAML.load_file(CACHE_FILE)
    else
      httpcall = Net::HTTP.new(INSTANCE_HOST)

      resp = httpcall.get(INSTANCE_ID_URL)
      instance_id = resp.body

      resp = httpcall.get(INSTANCE_REGION_URL)
      region = resp.body

      cache = {
        :instance_id => instance_id,
        :region => region,
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

      tags = Retriable.retriable tries: 10 do
        AWS.ec2.instances[instance_id].tags.to_h
      end

      tags.each_pair do | key, value |
        symbol = "ec2_tag_#{key.gsub(/\-|\//, '_')}".to_sym
        cache[symbol] = value
      end

      File.open(CACHE_FILE, 'w') {|f| f.write cache.to_yaml }
    end

    # cache is a hash so create a fact for each
    cache.each_pair do | key, value |
      Facter.add(key) { setcode { value } }
    end
  end

end
