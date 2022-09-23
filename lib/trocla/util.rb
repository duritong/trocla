require 'securerandom'
class Trocla
  # Utils
  class Util
    class << self
      def random_str(length = 12, charset = 'default')
        char = charsets[charset] || charsets['default']
        charsets_size = char.size
        (1..length).collect { |_| char[rand_num(charsets_size)] }.join.to_s
      end

      def salt(length = 8)
        random_str(length, 'alphanumeric')
      end

      private

      def rand_num(n)
        SecureRandom.random_number(n)
      end

      def charsets
        @charsets ||= begin
          h = {
            'default' => chars, 'alphanumeric' => alphanumeric, 'shellsafe' => shellsafe,
            'windowssafe' => windowssafe, 'numeric' => numeric, 'hexadecimal' => hexadecimal,
            'consolesafe' => consolesafe, 'typesafe' => typesafe
          }
          h.each { |k, v| h[k] = v.uniq }
        end
      end

      def chars
        @chars ||= shellsafe + special_chars
      end

      def shellsafe
        @shellsafe ||= alphanumeric + shellsafe_chars
      end

      def windowssafe
        @windowssafe ||= alphanumeric + windowssafe_chars
      end

      def consolesafe
        @consolesafe ||= alphanumeric + consolesafe_chars
      end

      def hexadecimal
        @hexadecimal ||= numeric + ('a'..'f').to_a
      end

      def alphanumeric
        @alphanumeric ||= ('a'..'z').to_a + ('A'..'Z').to_a + numeric
      end

      def numeric
        @numeric ||= ('0'..'9').to_a
      end

      def typesafe
        @typesafe ||= ('a'..'x').to_a - ['i'] - ['l'] + ('A'..'X').to_a - ['I'] - ['L'] + ('1'..'9').to_a
      end

      def special_chars
        @special_chars ||= '*()&![]{}-'.split(//)
      end

      def shellsafe_chars
        @shellsafe_chars ||= '+%/@=?_.,:'.split(//)
      end

      def windowssafe_chars
        @windowssafe_chars ||= '+%/@=?_.,'.split(//)
      end

      def consolesafe_chars
        @consolesafe_chars ||= '+.-,_'.split(//)
      end
    end
  end
end
