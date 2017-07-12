require 'action_controller/railtie'
require 'rschema/rails'

RSpec.describe RSchema::Rails do
  include Rack::Test::Methods

  let(:app){ Rails5Host::Application }

  def request(method, *args)
    send(method, *args)
    Marshal.load(last_response.body)
  end

  it 'validates and coerces the input params' do
    result = request(:post, '/inline_schema', { 'pig' => 'oink' })
    expect(result).to be_valid
    expect(result.value).to eq({
      duck: [],
      pig: :oink,
    })
  end

  it 'raises errors with #validate_params!' do
    expect {
      request(:post, '/raising_schema', { 'thing' => 'hello' })
    }.to raise_error(RSchema::Rails::InvalidParams)
  end
end

module Rails5Host
  class TestController < ActionController::Base
    include RSchema::Rails::Controller

    CLASS_LEVEL_SCHEMA = param_schema {{ thing: _Integer }}

    def inline_schema
      result = validate_params {{
        duck: array(_String),
        optional(:pig) => enum([:oink, :ree]),
      }}

      render_result(result)
    end

    def separate_schema
      schema = param_schema {{ thing: _Integer }}
      result = validate_params(schema)
      render_result(result)
    end

    def raising_schema
      result = validate_params! {{ thing: _Integer }}
      render_result(result)
    end

    def render_result(result)
      render plain: Marshal.dump(result)
    end
  end

  class Application < Rails::Application
    routes.append do
      post 'inline_schema', controller: 'rails_5_host/test'
      post 'separate_schema', controller: 'rails_5_host/test'
      post 'raising_schema', controller: 'rails_5_host/test'
    end

    config.secret_key_base = SecureRandom.hex(30)
    config.eager_load = false
    config.consider_all_requests_local = true
    config.logger = Logger.new('/dev/null')
    config.middleware.delete(ActionDispatch::ShowExceptions)
    config.middleware.delete(ActionDispatch::DebugExceptions)
  end

  Application.initialize!
end

