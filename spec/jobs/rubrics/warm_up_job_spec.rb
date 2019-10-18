# frozen_string_literal: true

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
      expect { run_job }.to raise_error('wrong photo size zozo')
    end
  end

  context 'when thumb photo size' do
    let(:photo_size) { :thumb }

    it do
      expect { run_job }.to raise_error('wrong photo size thumb')
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

  context 'when real thumb request' do
    let(:photo_size) { :max }
    let(:token) { create :'yandex/token', dir: '/photos' }

    let!(:published_photo1) do
      create :photo, :fake, storage_filename: '000/002/1399af5ae507b68fa87cf9c608be76b6736a8789ff7c.jpg',
                            width: 4_096, height: 3_072, yandex_token: token, rubric: rubric
    end

    let!(:published_photo2) do
      create :photo, :fake, storage_filename: '000/002/13980400eed762a03139516b0763ab5975f07bbce466.jpg',
                            width: 4_096, height: 3_072, yandex_token: token, rubric: rubric
    end

    before do
      allow_any_instance_of(Photo).to receive(:yandex_token_id).and_return(1)
      allow(Rails.application.routes).
        to receive(:default_url_options).and_return(protocol: 'https', host: 'photo.mytm.tk')
    end

    subject { VCR.use_cassette('rubric_warm_up_real') { run_job } }

    it do
      expect { subject }.not_to raise_error
    end
  end

  after { Sidekiq::Worker.clear_all }
end
