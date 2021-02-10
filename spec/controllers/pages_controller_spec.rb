# frozen_string_literal: true

RSpec.describe PagesController, type: :request do
  describe '#show' do
    let!(:rubric) { create :rubric }
    let(:token) { create :'yandex/token' }

    context 'when root' do
      context 'and without rubrics' do
        before { get root_url }

        it do
          expect(response).to have_http_status(:ok)

          expect(assigns(:rubric)).to be_nil
          expect(assigns(:summary)).to be_nil
        end
      end

      context 'and with published photos' do
        before do
          create :rubric
          create :rubric, rubric: rubric

          create(:photo, rubric: rubric, yandex_token: token, storage_filename: 'test')

          get root_url
        end

        it do
          expect(response).to have_http_status(:ok)

          expect(assigns(:rubric)).to be_nil
          expect(assigns(:summary)).to be_nil
        end
      end
    end

    context 'when rubric' do
      context 'and without photos and rubrics' do
        before do
          create :photo, local_filename: 'test', rubric: rubric

          get page_url(id: rubric.id)
        end

        it do
          expect(response).to redirect_to(root_path)

          expect(assigns(:rubric)).to eq(rubric)
          expect(assigns(:summary)).to be_nil
        end
      end

      context 'and with published photos' do
        before do
          create :photo, storage_filename: 'test', rubric: rubric, yandex_token: token

          get page_url(id: rubric.id)
        end

        it do
          expect(response).to have_http_status(:ok)

          expect(assigns(:rubric)).to eq(rubric)
          expect(assigns(:summary)).to be_nil
        end
      end

      context 'and with sub rubric without published photo' do
        before do
          create :rubric, rubric: rubric

          get page_url(id: rubric.id)
        end

        it do
          expect(response).to redirect_to(root_path)

          expect(assigns(:rubric)).to eq(rubric)
          expect(assigns(:summary)).to be_nil
        end
      end

      context 'and with sub rubric with published photo' do
        let(:sub_rubric) { create :rubric, rubric: rubric }

        before do
          create :photo, storage_filename: 'test', rubric: sub_rubric, yandex_token: token

          get page_url(id: rubric.id)
        end

        it do
          expect(response).to have_http_status(:ok)

          expect(assigns(:rubric)).to eq(rubric)
          expect(assigns(:summary)).to be_nil
        end
      end

      context 'and with published photos but with zero photo counter' do
        before do
          create :photo, storage_filename: 'test', rubric: rubric, yandex_token: token

          Rubric.where(id: rubric.id).update_all(photos_count: 0)

          get page_url(id: rubric.id)
        end

        it do
          expect(response).to redirect_to(root_path)

          expect(assigns(:rubric)).to eq(rubric)
          expect(assigns(:summary)).to be_nil
        end
      end

      context 'and with sub rubric with published photo but with zero counter' do
        let(:other_rubric) { create :rubric, rubric: rubric }

        before do
          create :photo, storage_filename: 'test', rubric: other_rubric, yandex_token: token

          Rubric.where(id: rubric.id).update_all(rubrics_count: 0)

          get page_url(id: rubric.id)
        end

        it do
          expect(response).to redirect_to(root_path)

          expect(assigns(:rubric)).to eq(rubric)
          expect(assigns(:summary)).to be_nil
        end
      end

      context 'when with tracks and photos' do
        before do
          create :photo, storage_filename: 'test', rubric: rubric, yandex_token: token
          create :track, local_filename: '1.gpx', rubric: rubric

          get page_url(id: rubric.id)
        end

        it do
          expect(response).to have_http_status(:ok)

          expect(assigns(:rubric)).to eq(rubric)
          expect(assigns(:summary)).not_to be_nil
        end
      end
    end
  end
end
