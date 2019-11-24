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
    allow(Rails.application.credentials).to receive(:proxy).and_return(secret: 'secret', iv: '389ed464a551f644')
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
    let(:session_value) { generate_proxy_session(1.day.from_now.to_i) }

    before do
      request.cookies['proxy_session'] = session_value

      get :index
    end

    it do
      expect(response.cookies['proxy_session']).to be_nil
    end
  end
end
