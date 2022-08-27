# frozen_string_literal: true

RSpec.describe Listing::Item do
  let(:token) { create :'yandex/token' }
  let(:rubric) { create :rubric }
  let(:photo) do
    create :photo,
           yandex_token: token,
           rubric:,
           storage_filename: 'test.jpg',
           width: 100,
           height: 200,
           rotated: 1
  end

  let(:item) { described_class.new(attrs) }

  let(:default_rubric_attrs) do
    rubric.attributes.merge(
      model_type: 'Rubric',
      yandex_token: nil,
      content_type: nil,
      height: nil,
      width: nil,
      lat_long: nil,
      props: nil,
      storage_filename: nil,
      yandex_token_id: nil,
      folder_index: nil
    )
  end

  let(:default_photo_attrs) do
    photo.attributes.merge(
      model_type: 'Photo',
      photos_count: 10,
      rubrics_count: 20,
      yandex_token: token
    )
  end

  before do
    allow(Rails.application.config).to receive(:photo_sizes).and_return(
      thumb: ->(photo) { photo.width * 360 / photo.height }
    )
  end

  describe 'validation' do
    context 'when correct values' do
      let(:attrs) { default_photo_attrs }

      it do
        expect(item).to have_attributes(
          id: photo.id,
          yandex_token: token,
          yandex_token_id: token.id,
          storage_filename: 'test.jpg',
          content_type: photo.content_type,
          width: 100,
          height: 200,
          lat_long: nil,
          props: {'rotated' => 1},
          rubric_id: rubric.id,
          model_type: 'Photo',
          photos_count: 10,
          rubrics_count: 20,
          folder_index: 0
        )

        expect(item.video?).to be(false)
      end
    end

    context 'when some attributes not found' do
      let(:attrs) { photo.attributes }

      it do
        expect { item }.
          to raise_error('following attrs are not assigned: model_type,photos_count,rubrics_count,yandex_token')
      end
    end
  end

  describe '#name' do
    context 'when photo' do
      let(:attrs) { default_photo_attrs }

      it { expect(item.name).to eq(photo.name) }
    end

    context 'when empty rubric' do
      let(:attrs) { default_rubric_attrs }

      it { expect(item.name).to eq(rubric.name) }
    end

    context 'when rubric with photos' do
      let(:attrs) { default_rubric_attrs.merge(photos_count: 1) }

      it { expect(item.name).to eq("#{rubric.name}, фото: 1") }
    end

    context 'when rubric with rubrics' do
      let(:attrs) { default_rubric_attrs.merge(rubrics_count: 5) }

      it { expect(item.name).to eq("#{rubric.name}, подрубрик: 5") }
    end

    context 'when rubric with photos and rubrics' do
      let(:attrs) { default_rubric_attrs.merge(rubrics_count: 5, photos_count: 3) }

      it { expect(item.name).to eq("#{rubric.name}, подрубрик: 5, фото: 3") }
    end
  end

  describe '#image_size' do
    context 'when without a photo' do
      let(:attrs) { default_rubric_attrs }

      it do
        expect(item.image_size).to eq([480, 360])
        expect(item.image_size(apply_rotation: true)).to eq([480, 360])
      end
    end

    context 'when with a photo' do
      let(:attrs) { default_photo_attrs }

      it do
        expect(item.image_size).to eq([360, 720])
        expect(item.image_size(apply_rotation: true)).to eq([720, 360])
      end
    end
  end

  describe '#proxy_url' do
    let(:attrs) { default_photo_attrs }

    it { expect(item.proxy_url).to eq("/proxy/yandex/previews/test_photos/test.jpg?id=#{token.id}&size=360") }
  end

  describe '#rubric?' do
    subject(:rubric?) { item.rubric? }

    let(:attrs) do
      photo.attributes.merge!(
        model_type:,
        photos_count: 0,
        rubrics_count: 0,
        yandex_token: token,
        folder_index: nil
      )
    end

    context 'when photo' do
      let(:model_type) { 'Photo' }

      it { is_expected.to be(false) }
    end

    context 'when rubric' do
      let(:model_type) { 'Rubric' }

      it { is_expected.to be(true) }
    end

    context 'when wrong type' do
      let(:model_type) { 'Wrong' }

      it { is_expected.to be(false) }
    end
  end

  describe 'video attrs' do
    let(:attrs) do
      default_photo_attrs.merge!(
        content_type: 'video/mp4',
        props: {
          preview_filename: '1.jpg'
        }
      )
    end

    it do
      expect(item.video?).to be(true)
      expect(item.preview_filename).to eq('1.jpg')
    end
  end

  describe '#css_transform' do
    let(:attrs) { default_photo_attrs }

    it { expect(item.css_transform).to eq('rotate(90deg)') }
  end

  describe '#turned?' do
    let(:attrs) { default_photo_attrs }

    it { expect(item.turned?).to be(true) }
  end

  describe '#rotated' do
    context 'when photo with props' do
      let(:attrs) { default_photo_attrs }

      it { expect(item.rotated).to eq(1) }
    end

    context 'when photo without props' do
      let(:attrs) { default_photo_attrs.merge(rotated: nil, props: nil) }

      it do
        expect(item.props).to be_nil
        expect(item.rotated).to be_nil
      end
    end
  end

  describe '#effects' do
    context 'when photo with props' do
      let(:photo) do
        create :photo,
               yandex_token: token,
               rubric:,
               storage_filename: 'test.jpg',
               effects: %w[scaleX(-1)]
      end

      let(:attrs) { default_photo_attrs }

      it { expect(item.effects).to eq(%w[scaleX(-1)]) }
    end

    context 'when photo without props' do
      let(:attrs) { default_photo_attrs.merge(props: nil) }

      it do
        expect(item.props).to be_nil
        expect(item.effects).to be_nil
      end
    end
  end
end
