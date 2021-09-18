# frozen_string_literal: true

RSpec.describe Rubrics::WarmUpJob do
  subject(:perform!) { described_class.new.perform(rubric_id, photo_size) }

  let(:photo_size) { :max }
  let(:rubric_id) { rubric.id }

  context 'when rubric does not exist' do
    let(:rubric_id) { 100 }

    it do
      expect { perform! }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when wrong image size' do
    let!(:rubric) { create :rubric }
    let(:photo_size) { :wrong }

    it do
      expect(rubric).to be_persisted

      expect { perform! }.to raise_error('wrong photo size: wrong')
    end
  end

  context 'when rubric with some photos' do
    let(:rubric) { create :rubric }
    let(:token) { create :'yandex/token' }
    let!(:stubbing) do
      stub_request(
        :any,
        Regexp.new(Rails.application.routes.default_url_options.fetch(:host))
      ).to_return(body: '')
    end

    before do
      create :photo, rubric: rubric, storage_filename: 'test.jpg', yandex_token: token, width: 1_000, height: 500
      create :photo, rubric: rubric, storage_filename: 'test.jpg', yandex_token: token, width: 1_000, height: 500
    end

    it do
      expect { perform! }.not_to raise_error

      expect(stubbing).to have_been_requested.twice
    end
  end
end
