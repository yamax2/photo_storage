# frozen_string_literal: true

::Yandex::Token.ransacker :free_space do
  Arel.sql('total_space - used_space')
end
