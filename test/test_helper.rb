ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'shoulda-context'
require 'shoulda-matchers'
require 'factory_bot_rails'
require 'custom_assertions'
require 'view_model_test_helper'