# frozen_string_literal: true

# Негативные версии матчеров для композиции через .and (`expect { } .to not_change(...).and ...`)
RSpec::Matchers.define_negated_matcher :not_change, :change
