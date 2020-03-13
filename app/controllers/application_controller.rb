class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  around_filter :error_handling

  def index
    render nothing: true
  end

  private

  def reply(text=nil, in_channel: false, attachments: [])
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

    computed_signature = SlackHelper.signature(timestamp: request.headers['X-Slack-Request-Timestamp'], raw_body: request.body.read)
    slack_signature = request.headers['X-Slack-Signature']

    render nothing: true, status: :unauthorized unless computed_signature == slack_signature
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
