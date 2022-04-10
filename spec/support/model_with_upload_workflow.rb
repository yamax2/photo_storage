# frozen_string_literal: true

RSpec.shared_context 'model with upload workflow' do |factory|
  describe 'structure' do
    it { is_expected.to have_db_column(:yandex_token_id).of_type(:integer).with_options(null: true) }
    it { is_expected.to have_db_column(:local_filename).of_type(:text) }
  end

  describe 'token presence validation' do
    context 'when not uploaded' do
      subject { build factory, local_filename: 'test', yandex_token: nil }

      it { is_expected.to be_valid }
    end

    context 'when uploaded' do
      context 'and token is not assigned' do
        subject(:model) { build factory, storage_filename: 'test', yandex_token: nil }

        it do
          expect(model).not_to be_valid
          expect(model.errors).to include(:yandex_token)
        end
      end

      context 'and token is assigned' do
        subject(:model) { build factory, storage_filename: 'test', yandex_token: token }

        let(:token) { create :'yandex/token' }

        it { expect(model).to be_valid }
      end
    end
  end

  describe 'upload status validation' do
    context 'when both attributes present' do
      subject(:model) { build factory, storage_filename: 'zozo', local_filename: 'test' }

      it do
        expect(model).not_to be_valid
        expect(model.errors).to include(:local_filename)
      end
    end

    context 'when storage_filename presents' do
      subject(:model) { build factory, storage_filename: 'zozo', local_filename: nil, yandex_token: token }

      let(:token) { create :'yandex/token' }

      it { expect(model).to be_valid }
    end

    context 'when local_filename presents' do
      subject(:model) { build factory, storage_filename: nil, local_filename: 'test' }

      it { expect(model).to be_valid }
    end

    context 'when both attributes empty' do
      subject(:model) { build factory, storage_filename: nil, local_filename: nil }

      it do
        expect(model).not_to be_valid
        expect(model.errors).to include(:local_filename)
      end
    end
  end

  describe 'scopes' do
    let(:token) { create :'yandex/token' }
    let!(:uploaded) { create_list factory, 2, storage_filename: 'test', yandex_token: token }
    let!(:pending) { create_list factory, 2, local_filename: 'zozo' }

    describe '#uploaded' do
      it { expect(described_class.uploaded).to match_array(uploaded) }
    end

    describe '#pending' do
      it { expect(described_class.pending).to match_array(pending) }
    end
  end

  describe '#local_file?' do
    subject { model.local_file? }

    context 'when local_filename is empty' do
      let(:token) { create :'yandex/token' }
      let(:model) { create factory, local_filename: nil, storage_filename: 'zozo', yandex_token: token }

      it { is_expected.to be(false) }
    end

    context 'when local_filename is not empty' do
      let(:model) { create factory, local_filename: 'test.txt' }

      context 'and file exists' do
        before do
          FileUtils.mkdir_p(Rails.root.join('tmp/files'))
          FileUtils.cp 'spec/fixtures/test.txt', Rails.root.join('tmp/files/test.txt')
        end

        after do
          FileUtils.rm_f Rails.root.join('tmp/files/test.txt')
        end

        it { is_expected.to be(true) }
      end

      context 'and file does not exist' do
        it { is_expected.to be(false) }
      end
    end
  end

  describe '#tmp_local_filename' do
    let(:model) { create factory, local_filename: 'test' }

    it do
      expect(model.tmp_local_filename).to eq(Rails.root.join('tmp/files/test'))
    end
  end

  describe 'local file removing' do
    let(:tmp_file) { Rails.root.join('tmp/files/cats.jpg') }
    let(:model) { create factory, local_filename: 'cats.jpg' }

    before do
      FileUtils.mkdir_p(Rails.root.join('tmp/files'))
      FileUtils.cp('spec/fixtures/cats.jpg', tmp_file)
    end

    after { FileUtils.rm_f(tmp_file) }

    context 'when update' do
      before { model.update!(name: 'test1') }

      it do
        expect(File.exist?(tmp_file)).to be(true)
      end
    end

    context 'when destroy' do
      subject(:action!) { model.destroy }

      context 'and local_file is not empty' do
        before { action! }

        it do
          expect(File.exist?(tmp_file)).to be(false)
        end
      end

      context 'and local_file is not exist' do
        let(:model) { create factory, local_filename: 'cats1.jpg' }

        it do
          expect { action! }.not_to raise_error
        end
      end
    end
  end

  describe 'file attrs loading' do
    context 'when local file' do
      let(:model) { build factory, :real, local_filename: 'test.txt' }
      let(:tmp_file) { Rails.root.join('tmp/files/test.txt') }

      before do
        FileUtils.mkdir_p(Rails.root.join('tmp/files'))
        FileUtils.cp 'spec/fixtures/test.txt', tmp_file
      end

      after do
        FileUtils.rm_f(tmp_file)
      end

      it do
        expect { model.save! }.
          to change(model, :md5).from(nil).to(String).
          and change(model, :sha256).from(nil).to(String)
      end
    end

    context 'when remote file' do
      let(:token) { create :'yandex/token' }
      let(:model) { build factory, storage_filename: 'test.txt', yandex_token: token }

      let(:initial_md5) { model.md5 }
      let(:initial_sha) { model.sha256 }

      before do
        initial_md5
        initial_sha

        model.save!
      end

      it do
        expect(model.md5).to eq(initial_md5)
        expect(model.sha256).to eq(initial_sha)
      end
    end
  end

  describe 'size loading' do
    let(:tmp_file) { Rails.root.join('tmp/files/test.txt') }

    context 'when local file' do
      before do
        FileUtils.mkdir_p(Rails.root.join('tmp/files'))
        FileUtils.cp 'spec/fixtures/test.txt', tmp_file
      end

      after { FileUtils.rm_f(tmp_file) }

      context 'when size = 0' do
        let(:model) { build factory, local_filename: 'test.txt', size: 0 }

        it do
          expect { model.save! }.to change(model, :size).from(0).to(File.size(tmp_file))
        end
      end

      context 'when size > 0' do
        let(:model) { build factory, local_filename: 'test.txt', size: 10 }

        it do
          expect { model.save! }.not_to change(model, :size)
        end
      end
    end

    context 'when remote file' do
      let(:token) { create :'yandex/token' }
      let(:model) { build factory, storage_filename: 'test.txt', yandex_token: token, size: 0 }

      it do
        expect { model.save! }.not_to change(model, :size)
      end
    end
  end
end
