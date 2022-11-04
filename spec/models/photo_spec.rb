# frozen_string_literal: true

RSpec.describe Photo do
  it_behaves_like 'storable model'

  it_behaves_like 'model with upload workflow', :photo
  it_behaves_like 'model with counter', :photo

  describe 'structure' do
    let(:tz) { Rails.application.config.time_zone }

    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false, limit: 512) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:rubric_id).of_type(:integer).with_options(null: false) }

    it { is_expected.to have_db_column(:exif).of_type(:jsonb) }
    it { is_expected.to have_db_column(:lat_long).of_type(:point) }
    it { is_expected.to have_db_column(:original_timestamp).of_type(:datetime).with_options(null: true) }
    it { is_expected.to have_db_column(:content_type).of_type(:string).with_options(null: false, limit: 30) }
    it { is_expected.to have_db_column(:width).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:height).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:views).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:tz).of_type(:string).with_options(null: false, limit: 50, default: tz) }
    it { is_expected.to have_db_column(:props).of_type(:jsonb).with_options(null: false, default: {}) }

    it { is_expected.to have_db_index(:rubric_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:yandex_token).inverse_of(:photos).optional }
    it { is_expected.to belong_to(:rubric).inverse_of(:photos).counter_cache(true) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(512) }

    it { is_expected.to validate_presence_of(:width) }
    it { is_expected.to validate_numericality_of(:width).is_greater_than_or_equal_to(0).only_integer }

    it { is_expected.to validate_presence_of(:height) }
    it { is_expected.to validate_numericality_of(:height).is_greater_than_or_equal_to(0).only_integer }

    it { is_expected.to validate_presence_of(:content_type) }
    it { is_expected.to validate_inclusion_of(:content_type).in_array(described_class::ALLOWED_CONTENT_TYPES) }

    it { is_expected.to validate_inclusion_of(:tz).in_array(Rails.application.config.photo_timezones) }

    it { is_expected.to validate_inclusion_of(:rotated).in_array([1, 2, 3]).allow_blank }
    it { is_expected.to validate_numericality_of(:rotated).only_integer }

    it { is_expected.to validate_absence_of(:preview_filename) }
    it { is_expected.to validate_absence_of(:preview_size) }
    it { is_expected.to validate_absence_of(:preview_md5) }
    it { is_expected.to validate_absence_of(:preview_sha256) }

    it { is_expected.to validate_absence_of(:video_preview_filename) }
    it { is_expected.to validate_absence_of(:video_preview_size) }
    it { is_expected.to validate_absence_of(:video_preview_md5) }
    it { is_expected.to validate_absence_of(:video_preview_sha256) }
    it { is_expected.to validate_absence_of(:duration) }
  end

  describe 'video validations' do
    subject(:model) { build :photo, :video }

    it { is_expected.to validate_absence_of(:local_filename) }
    it { is_expected.to validate_absence_of(:rotated) }
    it { is_expected.to validate_absence_of(:effects) }
    it { is_expected.to validate_presence_of(:storage_filename) }

    it { is_expected.to validate_presence_of(:preview_filename) }
    it { is_expected.to validate_presence_of(:preview_size) }
    it { is_expected.to validate_numericality_of(:preview_size).is_greater_than(0).only_integer }
    it { is_expected.to validate_presence_of(:preview_md5) }
    it { is_expected.to validate_presence_of(:preview_sha256) }
    it { is_expected.to validate_length_of(:preview_md5).is_equal_to(32) }
    it { is_expected.to validate_length_of(:preview_sha256).is_equal_to(64) }

    it { is_expected.to validate_presence_of(:video_preview_filename) }
    it { is_expected.to validate_presence_of(:video_preview_size) }
    it { is_expected.to validate_numericality_of(:video_preview_size).is_greater_than(0).only_integer }
    it { is_expected.to validate_presence_of(:video_preview_md5) }
    it { is_expected.to validate_presence_of(:video_preview_sha256) }
    it { is_expected.to validate_length_of(:video_preview_md5).is_equal_to(32) }
    it { is_expected.to validate_length_of(:video_preview_sha256).is_equal_to(64) }
  end

  describe 'scopes' do
    let(:token) { create :'yandex/token' }

    before do
      described_class::ALLOWED_CONTENT_TYPES.each do |content_type|
        model = build(:photo, content_type:, yandex_token: token, storage_filename: 'test')

        if model.video?
          model.assign_attributes(
            preview_size: 10,
            preview_filename: 'test',
            preview_md5: Digest::MD5.hexdigest(SecureRandom.hex(32)),
            preview_sha256: Digest::SHA256.hexdigest(SecureRandom.hex(32)),

            video_preview_size: 20,
            video_preview_filename: 'test.preview',
            video_preview_md5: Digest::MD5.hexdigest(SecureRandom.hex(32)),
            video_preview_sha256: Digest::SHA256.hexdigest(SecureRandom.hex(32))
          )
        end

        model.save!
      end
    end

    it do
      expect(described_class.images.count).to eq(4)
      expect(described_class.videos.count).to eq(2)
    end
  end

  describe 'effects validation' do
    subject(:photo) { build :photo, effects:, local_filename: '1.jpg' }

    context 'when value is not an array' do
      let(:effects) { '   ' }

      it do
        expect(photo).not_to be_valid
        expect(photo.errors).to include(:effects)
      end
    end

    context 'when nil value' do
      let(:effects) { nil }

      it { is_expected.to be_valid }
    end

    context 'when correct value' do
      let(:effects) { %w[scaleX(-1) scaleY(100)] }

      it { is_expected.to be_valid }
    end

    context 'when one item is incorrect' do
      let(:effects) { %w[scaleX(-1a) scaleY(100)] }

      it do
        expect(photo).not_to be_valid
        expect(photo.errors).to include(:effects)
      end
    end
  end

  describe 'strip attributes' do
    it { is_expected.to strip_attribute(:name) }
    it { is_expected.to strip_attribute(:description) }
    it { is_expected.to strip_attribute(:content_type) }
  end

  describe 'remote file removing' do
    let(:node) { create :'yandex/token', other_dir: '/other', dir: '/dir' }
    let(:job_args) { enqueued_jobs(klass: Yandex::RemoveFileJob).pluck('args') }

    context 'when model is not uploaded' do
      let(:photo) { create :photo, local_filename: 'zozo.jpg', yandex_token: node }

      it do
        expect { photo.destroy }.
          not_to(change { enqueued_jobs(klass: Yandex::RemoveFileJob).size })
      end
    end

    context 'when image' do
      let(:photo) { create :photo, storage_filename: '052/001/zozo.jpg', yandex_token: node }

      it do
        expect { photo.destroy }.to change { enqueued_jobs(klass: Yandex::RemoveFileJob).size }.by(1)

        expect(job_args).to eq([[node.id, '/dir/052/001/zozo.jpg']])
      end
    end

    context 'when video' do
      let(:video) do
        create :photo,
               :video,
               storage_filename: 'test.mp4',
               preview_filename: 'test.jpg',
               video_preview_filename: 'test.preview.mp4',
               yandex_token: node
      end

      it do
        expect { video.destroy }.
          to change { enqueued_jobs(klass: Yandex::RemoveFileJob).size }.by(3)

        expect(job_args).to match_array(
          [[node.id, '/other/test.mp4'], [node.id, '/other/test.jpg'], [node.id, '/other/test.preview.mp4']]
        )
      end
    end

    context 'when invalid video from previous release' do
      let(:rubric) { create :rubric }
      let(:video) do
        build(
          :photo,
          :video,
          storage_filename: 'test.mp4',
          preview_filename: '  ',
          video_preview_filename: nil,
          yandex_token: node,
          rubric:
        ).tap { |video| video.save(validate: false) }
      end

      it do
        expect(video).to be_persisted
        expect(video).not_to be_valid

        expect { video.destroy }.
          to change { enqueued_jobs(klass: Yandex::RemoveFileJob).size }.by(1)

        expect(job_args).to match_array(
          [[node.id, '/other/test.mp4']]
        )
      end
    end

    context 'when job for preview enqueued with an error' do
      let(:video) do
        create :photo,
               :video,
               storage_filename: 'test.mp4',
               preview_filename: 'test.jpg',
               video_preview_filename: 'test.preview.mp4',
               yandex_token: node
      end

      before do
        allow(Yandex::RemoveFileJob).to receive(:perform_async).and_call_original
        allow(Yandex::RemoveFileJob).to receive(:perform_async).with(
          node.id,
          '/other/test.preview.mp4'
        ).and_raise('boom!')
      end

      it do
        expect { video.destroy }.
          to raise_error('boom!').
          and change { enqueued_jobs(klass: Yandex::RemoveFileJob).size }.by(0)
      end
    end
  end

  describe 'position in cart' do
    before { allow(Cart::PhotoService).to receive(:call!) }

    let(:rubric) { create :rubric }
    let(:photo) { create :photo, local_filename: 'test', rubric: }

    context 'when try to change name' do
      before do
        photo.name = "#{photo.name}test"
        photo.save!
      end

      it do
        expect(Cart::PhotoService).not_to have_received(:call!)
      end
    end

    context 'when rubric changed' do
      let(:new_rubric) { create :rubric }

      before do
        photo.rubric = new_rubric
        photo.save!
      end

      it do
        expect(photo.rubric).to eq(new_rubric)
        expect(::Cart::PhotoService).
          to have_received(:call!).with(photo:, remove: true).once
      end
    end

    context 'when photo destroyed' do
      before { photo.destroy }

      it do
        expect(photo).not_to be_persisted
        expect(::Cart::PhotoService).
          to have_received(:call!).with(photo:, remove: true).once
      end
    end

    context 'when try to change rubric for a new photo' do
      let(:photo) { build :photo, local_filename: 'test', rubric: }
      let(:new_rubric) { create :rubric }

      before do
        photo.rubric = new_rubric
        photo.save!
      end

      it do
        expect(photo.rubric).to eq(new_rubric)
        expect(Cart::PhotoService).not_to have_received(:call!)
      end
    end
  end

  describe 'rubric changing' do
    let(:old_rubric) { create :rubric }
    let(:new_rubric) { create :rubric }

    context 'when photo is persisted' do
      let(:photo) { create :photo, local_filename: 'test', rubric: old_rubric }

      before do
        Rubric.where(id: old_rubric.id).update_all(main_photo_id: photo.id)
      end

      it do
        expect { photo.update!(rubric: new_rubric) }.
          to change(photo, :rubric).from(old_rubric).to(new_rubric).
          and change { old_rubric.reload.main_photo }.from(photo).to(nil).
          and change { new_rubric.reload.main_photo }.from(nil).to(photo)
      end
    end

    context 'when photo is not persisted' do
      subject(:change!) do
        photo.rubric = new_rubric
        photo.save!
      end

      let(:photo) { build :photo, local_filename: 'test', rubric: old_rubric }

      it do
        expect(::Photos::ChangeMainPhoto).not_to receive(:call!)

        expect { change! }.to change(photo, :rubric).from(old_rubric).to(new_rubric)
      end
    end

    context 'when move to a rubric with another main photo' do
      let(:photo) { create :photo, local_filename: 'test', rubric: old_rubric }
      let(:other_photo) { create :photo, local_filename: 'test', rubric: new_rubric }

      before do
        old_rubric.update!(main_photo_id: photo.id)
        new_rubric.update!(main_photo_id: other_photo.id)
      end

      it do
        expect { photo.update!(rubric: new_rubric) }.
          to change { photo.reload.rubric }.from(old_rubric).to(new_rubric).
          and change { old_rubric.reload.main_photo }.from(photo).to(nil)

        expect(new_rubric.reload.main_photo).to eq(other_photo)
      end
    end

    context 'when move to a deep rubric without main photo' do
      let(:old_rubric_parent) { create :rubric }
      let(:old_rubric) { create :rubric, rubric: old_rubric_parent }
      let(:photo) { create :photo, local_filename: 'test', rubric: old_rubric }

      let(:new_rubric_parent) { create :rubric }
      let(:new_rubric) { create :rubric, rubric: new_rubric_parent }

      before do
        Rubric.where(id: [old_rubric_parent.id, old_rubric.id]).update_all(main_photo_id: photo.id)
      end

      it do
        expect { photo.update!(rubric: new_rubric) }.
          to change { photo.reload.rubric }.from(old_rubric).to(new_rubric).
          and change { old_rubric.reload.main_photo }.from(photo).to(nil).
          and change { old_rubric_parent.reload.main_photo }.from(photo).to(nil).
          and change { new_rubric.reload.main_photo }.from(nil).to(photo).
          and change { new_rubric_parent.reload.main_photo }.from(nil).to(photo)
      end
    end
  end

  describe '#video?' do
    subject(:video?) { photo.video? }

    let(:photo) { build :photo, content_type: }

    context 'when video' do
      described_class::VIDEO_CONTENT_TYPES.each do |type|
        context "when content_type is #{type}" do
          let(:content_type) { type }

          it { is_expected.to be(true) }
        end
      end
    end

    context 'when empty content_type' do
      let(:content_type) { nil }

      it { is_expected.to be(false) }
    end

    context 'when photo' do
      let(:content_type) { 'image/png' }

      it { is_expected.to be(false) }
    end
  end

  describe '#jpeg?' do
    subject(:jpeg?) { photo.jpeg? }

    let(:photo) { build :photo, content_type: }

    context 'when jpeg' do
      described_class::JPEG_CONTENT_TYPES.each do |type|
        context "when content_type is #{type}" do
          let(:content_type) { type }

          it { is_expected.to be(true) }
        end
      end
    end

    context 'when empty content_type' do
      let(:content_type) { nil }

      it { is_expected.to be(false) }
    end

    context 'when not a jpeg' do
      let(:content_type) { 'image/png' }

      it { is_expected.to be(false) }
    end
  end
end
