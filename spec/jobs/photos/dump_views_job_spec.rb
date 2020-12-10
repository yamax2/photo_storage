# frozen_string_literal: true

RSpec.describe Photos::DumpViewsJob do
  before do
    allow(Counters::DumpService).to receive(:call!)
    described_class.perform_async
  end

  it do
    expect(Counters::DumpService).to have_received(:call!).with(model_klass: Photo)
  end
end
