require "facter/util/aws_tags"

begin
  Facter::Util::AWSTags.get_tags
rescue
end
