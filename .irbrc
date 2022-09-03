# frozen_string_literal: true

IRB.conf[:SAVE_HISTORY] = 1_000
IRB.conf[:HISTORY_FILE] = "#{Dir.home}/.irb-save-history"
IRB.conf[:USE_AUTOCOMPLETE] = false
