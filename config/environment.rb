# Load the Rails application.
require File.expand_path('../application', __FILE__)

AppConfig = YAML.load(ERB.new(Rails.root.join('config', 'config.yml').read).result)[Rails.env].with_indifferent_access

# Initialize the Rails application.
Rails.application.initialize!
