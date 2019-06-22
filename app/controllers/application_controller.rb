class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  before_filter :check_team_id
  around_filter :error_handling

  SLACK_ID_REGEX = '<([^\|>]*)[^>]*>'

  private

  def check_team_id
    return if params[:team_id].present?
    render json: {message: 'missing team_id'}, status: :bad_request
  end

  def reply(text, in_channel: false, attachments: [])
    raise "double reply. original messages:\n#{@response[:text]}\n#{text}" if @response.present?
    @response = {
        response_type: in_channel ? "in_channel" : "ephemeral",
        text: text,
        attachments: attachments
    }
  end

  def current_team
    params[:team_id]
  end

  def current_user
    "@#{params[:user_id]}"
  end

  def verify_slack_signature
    return if ENV['SKIP_SLACK_SIGNING'] # for easier dev debugging
    version_number = 'v0' # always v0 for now
    timestamp = request.headers['X-Slack-Request-Timestamp']
    raw_body = request.body.read
    sig_basestring = [version_number, timestamp, raw_body].join(':')

    signing_secret = ENV['SLACK_SIGNING_SECRET'].to_s
    digest = OpenSSL::Digest::SHA256.new
    hex_hash = OpenSSL::HMAC.hexdigest(digest, signing_secret, sig_basestring)
    computed_signature = [version_number, hex_hash].join('=')
    slack_signature = request.headers['X-Slack-Signature']

    render nothing: true, status: :unauthorized if computed_signature != slack_signature
  end

  def error_handling
    ActiveRecord::Base.transaction do
      yield
    end
  rescue => e
    message = "#{e.message}\n#{e.backtrace.first(5).join("\n")}"
    Rails.logger.error message
    text = Rails.env.development? ? message : "Uh oh! Something went wrong. Please contact Alex. :dusty_stick:"
    render json: {text: text}, status: :ok
  end
end
