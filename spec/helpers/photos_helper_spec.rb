# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PhotosHelper do
  describe '#photo_size_selector_opts' do
    it do
      expect(helper.photo_size_selector_opts).to eq(
        "<option value=\"preview\">Обычный</option>\n<option value=\"max\">Большой</option>"
      )
    end
  end
end
