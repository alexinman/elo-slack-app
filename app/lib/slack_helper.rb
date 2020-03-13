class SlackHelper
  def self.signature(timestamp:, raw_body:, version_number:'v0')
    sig_basestring = [version_number, timestamp, raw_body].join(':')
    signing_secret = ENV['SLACK_SIGNING_SECRET'].to_s
    digest = OpenSSL::Digest::SHA256.new
    hex_hash = OpenSSL::HMAC.hexdigest(digest, signing_secret, sig_basestring)
    [version_number, hex_hash].join('=')
  end
end