# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController do
  render_views

  controller(ApplicationController) do
    def index
      head :ok
    end
  end

  before do
    allow(Rails.application.credentials.proxy).to receive(:fetch).with(:secret).and_return('secret')
    allow(Rails.application.routes.default_url_options).to receive(:[]).with(:host).and_return('example.com')
  end

  context 'when session is empty' do
    before do
      request.cookies['proxy_session'] = nil

      get :index
    end

    it do
      expect(response.cookies['proxy_session']).not_to be_empty
    end
  end

  context 'when session is incorrect' do
    let(:session_value) { 'zozo' }

    before do
      request.cookies['proxy_session'] = session_value

      get :index
    end

    it do
      expect(response.cookies['proxy_session']).not_to eq(session_value)
      expect(response.cookies['proxy_session']).not_to be_empty
    end
  end

  context 'when session is not expired' do
    let(:session_value) { generate_proxy_session({started: Time.current.to_i}.to_json) }

    before do
      request.cookies['proxy_session'] = session_value

      get :index
    end

    it do
      expect(response.cookies['proxy_session']).to be_nil
    end
  end
end
