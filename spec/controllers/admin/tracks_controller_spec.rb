# frozen_string_literal: true

RSpec.describe Admin::TracksController, type: :request do
  describe '#destroy' do
    context 'when wrong rubric' do
      let(:track) { create :track, local_filename: 'test' }

      it do
        expect { delete admin_rubric_track_url(rubric_id: track.rubric_id * 2, id: track.id) }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when wrong id' do
      let(:rubric) { create :rubric }

      it do
        expect { delete admin_rubric_track_url(rubric_id: rubric.id, id: 1) }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when correct params' do
      let(:track) { create :track, local_filename: 'test' }

      before { delete admin_rubric_track_url(rubric_id: track.rubric_id, id: track.id) }

      it do
        expect(response).to redirect_to(admin_rubric_tracks_path(track.rubric))
        expect(assigns(:track)).not_to be_persisted
        expect(flash[:notice]).to eq I18n.t('admin.tracks.destroy.success', name: track.name)

        expect { track.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when with auth' do
      let(:track) { create :track, local_filename: 'test' }
      let(:request_proc) do
        ->(headers) { delete admin_rubric_track_url(rubric_id: track.rubric_id, id: track.id), headers: }
      end

      it_behaves_like 'admin restricted route'
    end
  end

  describe '#edit' do
    context 'when correct id' do
      let(:track) { create :track, local_filename: 'test' }

      before { get edit_admin_rubric_track_url(rubric_id: track.rubric_id, id: track.id) }

      it do
        expect(response).to render_template(:edit)
        expect(response).to have_http_status(:ok)
        expect(assigns(:track)).to eq(track)
      end
    end

    context 'when wrong id' do
      let(:rubric) { create :rubric }

      it do
        expect { get edit_admin_rubric_track_url(rubric_id: rubric.id, id: 1) }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when wrong rubric' do
      let(:track) { create :track, local_filename: 'test' }

      it do
        expect { get edit_admin_rubric_track_url(rubric_id: track.rubric_id * 2, id: track.id) }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when with auth' do
      let(:track) { create :track, local_filename: 'test' }
      let(:request_proc) do
        ->(headers) { get edit_admin_rubric_track_url(rubric_id: track.rubric_id, id: track.id), headers: }
      end

      it_behaves_like 'admin restricted route'
    end
  end

  describe '#index' do
    context 'when wrong rubric_id' do
      it do
        expect { get admin_rubric_tracks_url(rubric_id: 2) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when correct rubric' do
      let(:rubric) { create :rubric }

      before { create_list :track, 30, rubric:, local_filename: 'test' }

      context 'and first page' do
        before { get admin_rubric_tracks_url(rubric_id: rubric.id) }

        it do
          expect(response).to render_template(:index)
          expect(response).to have_http_status(:ok)
          expect(assigns(:tracks).size).to eq(25)
        end
      end

      context 'when second page' do
        before { get admin_rubric_tracks_url(rubric_id: rubric.id, page: 2) }

        it do
          expect(response).to render_template(:index)
          expect(response).to have_http_status(:ok)
          expect(assigns(:tracks).size).to eq(5)
        end
      end

      context 'when wrong page' do
        before { get admin_rubric_tracks_url(rubric_id: rubric.id, page: 5) }

        it do
          expect(response).to render_template(:index)
          expect(response).to have_http_status(:ok)
          expect(assigns(:tracks)).to be_empty
        end
      end

      context 'when filter' do
        let!(:my_track) { create :track, name: 'zozo', rubric:, local_filename: 'test' }

        before { get admin_rubric_tracks_url(rubric_id: rubric.id, q: {name_cont: 'zo'}) }

        it do
          expect(response).to render_template(:index)
          expect(response).to have_http_status(:ok)
          expect(assigns(:tracks)).to contain_exactly(my_track)
        end
      end
    end

    context 'when auth' do
      let(:rubric) { create :rubric }
      let(:request_proc) { ->(headers) { get admin_rubric_tracks_url(rubric_id: rubric.id), headers: } }

      it_behaves_like 'admin restricted route'
    end
  end

  describe '#update' do
    context 'when wrong rubric_id' do
      let(:track) { create :track, local_filename: 'test' }

      it do
        expect { put admin_rubric_track_url(rubric_id: track.rubric_id * 2, id: track.id, track: {name: 'test'}) }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when wrong id' do
      let(:rubric) { create :rubric }

      it do
        expect { put admin_rubric_track_url(rubric_id: rubric.id, id: 1, track: {name: 'test'}) }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when record invalid' do
      let(:track) { create :track, local_filename: 'test', name: 'test' }

      before { put admin_rubric_track_url(rubric_id: track.rubric_id, id: track.id, track: {name: ''}) }

      it do
        expect(response).to render_template(:edit)
        expect(assigns(:track)).to eq(track)
        expect(assigns(:track)).not_to be_valid
      end
    end

    context 'when without required params' do
      let(:track) { create :track, local_filename: 'test', name: 'zozo' }

      it do
        expect { put admin_rubric_track_url(rubric_id: track.rubric_id, id: track.id, track1: {name: 'test'}) }.
          to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'when successful update' do
      let(:track) { create :track, local_filename: 'test', name: 'test', color: 'red' }

      before do
        put admin_rubric_track_url(rubric_id: track.rubric_id, id: track.id, track: {name: 'zozo', color: 'blue'})
      end

      it do
        expect(response).to redirect_to(admin_rubric_tracks_path(track.rubric))

        expect(assigns(:track)).to eq(track)
        expect(assigns(:track)).to have_attributes(name: 'zozo', color: 'blue')
      end
    end

    context 'when rubric changed' do
      let(:new_rubric) { create :rubric }
      let(:track) { create :track, local_filename: 'test', name: 'test' }

      before do
        put admin_rubric_track_url(
          rubric_id: track.rubric_id,
          id: track.id,
          track: {name: 'zozo', rubric_id: new_rubric.id}
        )
      end

      it do
        expect(response).to redirect_to(admin_rubric_tracks_path(new_rubric))
        expect(assigns(:track)).to eq(track)
        expect(track.reload).to have_attributes(name: 'zozo', rubric: new_rubric)
      end
    end

    context 'when with auth' do
      let(:track) { create :track, local_filename: 'test', name: 'test', color: 'red' }

      let(:request_proc) do
        lambda do |headers|
          put admin_rubric_track_url(rubric_id: track.rubric_id, id: track.id, track: {name: 'zozo'}), headers:
        end
      end

      it_behaves_like 'admin restricted route'
    end
  end
end
