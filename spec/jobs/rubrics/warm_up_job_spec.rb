require 'rails_helper'

RSpec.describe Rubrics::WarmUpJob do
  let(:token) { create :'yandex/token', dir: '/test' }
  let(:rubric) { create :rubric }

  let!(:published_photo1) do
    create :photo, :fake, storage_filename: '000/000/18ef3cef09b2bcffcb637905e3c7668871a9463d3.jpg',
                          width: 4_096, height: 3_072, yandex_token: token, rubric: rubric
  end

  let!(:published_photo2) do
    create :photo, :fake, storage_filename: '000/000/217881fe6f1ff99c098d69ac53c65f7db70b53998.jpg',
                          width: 4_096, height: 3_072, yandex_token: token, rubric: rubric
  end

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  let(:photo_size) { :preview }
  let(:run_job) do
    described_class.perform_async(rubric.id, photo_size)
    described_class.drain
  end

  context 'when successful warming up' do
    before do
      allow_any_instance_of(Photo).to receive(:yandex_token_id).and_return(1)
    end

    subject { VCR.use_cassette('rubric_warm_up_success') { run_job } }

    it do
      expect { subject }.not_to raise_error
    end
  end

  context 'when warming up failed' do
    before do
      allow_any_instance_of(Photo).to receive(:yandex_token_id).and_return(1_361)
    end

    subject { VCR.use_cassette('rubric_warm_up_fail') { run_job } }

    it do
      expect { subject }.to raise_error(/warming up error on photo id/)
    end
  end

  context 'when wrong photo size' do
    let(:photo_size) { :zozo }

    it do
      expect { run_job }.to raise_error(KeyError)
    end
  end

  context 'when photo size is a string' do
    let(:photo_size) { 'max' }

    before do
      allow_any_instance_of(Photo).to receive(:yandex_token_id).and_return(1)
    end

    subject { VCR.use_cassette('rubric_warm_up_success_max') { run_job } }

    it do
      expect { subject }.not_to raise_error
    end
  end

  after { Sidekiq::Worker.clear_all }
end
