# frozen_string_literal: true

class Trocla
  module VERSION
    MAJOR = 0
    MINOR = 8
    PATCH = 0
    BUILD = nil

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')

    def self.version
      STRING
    end
  end
end
