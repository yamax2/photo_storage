# frozen_string_literal: true

RSpec.describe Rubrics::TracksSummaryService do
  subject(:summary) { described_class.new(rubric_id).call }

  let(:sample_time) { Time.zone.local(2017, 1, 1) }

  context 'when without tracks in rubric' do
    let(:rubric_id) { 1 }

    it { is_expected.to be_nil }
  end

  context 'when some tracks exist' do
    let(:rubric_id) { rubric.id }
    let(:rubric) { create :rubric }
    let(:another_rubric) { create :rubric, rubric: }

    before do
      create :track, duration: 30.hours, distance: 20_000, local_filename: '3.gpx', rubric: another_rubric
    end

    context 'when without started_at' do
      before do
        create :track, duration: 2.hours, distance: 100, local_filename: '1.gpx', rubric: rubric
        create :track,
               duration: 3.hours,
               distance: 200,
               local_filename: '2.gpx',
               rubric:,
               finished_at: sample_time
      end

      it do
        expect(summary).to have_attributes(
          avg_speed: 60.0,
          duration: '5ч.',
          distance: 300.0,
          started_at: nil,
          finished_at: sample_time,
          travel_duration: nil
        )
      end
    end

    context 'when correct tracks' do
      before do
        create :track,
               duration: 2.hours,
               distance: 100,
               local_filename: '1.gpx',
               rubric: rubric,
               started_at: sample_time,
               finished_at: sample_time + 10.hours

        create :track,
               duration: 3.hours,
               distance: 200,
               local_filename: '2.gpx',
               rubric:,
               started_at: sample_time + 12.hours,
               finished_at: sample_time + 15.hours
      end

      it do
        expect(summary).to have_attributes(
          avg_speed: 60.0,
          duration: '5ч.',
          distance: 300.0,
          started_at: sample_time,
          finished_at: sample_time + 15.hours,
          travel_duration: '15ч.'
        )
      end
    end
  end
end
