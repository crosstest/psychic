module Crosstest
  class Psychic
    class Hints < Crosstest::Core::Dash
      field :options, Hash, default: {}
      field :tasks, Hash[String => String], default: {}
      field :samples, Hash[String => Pathname], default: {}
    end
  end
end
