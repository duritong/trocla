require 'securerandom'
class Trocla
  class Util
    class << self
      def random_str(length=12, charset='default')
        _charsets = charsets[charset] || charsets['default']
        (1..length).collect{|a| _charsets[SecureRandom.random_number(_charsets.size)] }.join.to_s
      end

      def salt(length=8)
        alphanumeric_size = alphanumeric.size
        (1..length).collect{|a| alphanumeric[SecureRandom.random_number(alphanumeric_size)] }.join.to_s
      end

      private

      def charsets
        @charsets ||= {
          'default'      => chars,
          'alphanumeric' => alphanumeric,
          'shellsafe'    => shellsafe,
          'windowssafe'  => windowssafe,
          'numeric'      => numeric,
          'hexadecimal'  => hexadecimal,
          'consolesafe'  => consolesafe,
        }
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
      def special_chars
        @special_chars ||= "*()&![]{}-".split(//)
      end
      def shellsafe_chars
        @shellsafe_chars ||= "+%/@=?_.,:".split(//)
      end
      def windowssafe_chars
        @windowssafe_chars ||= "+%/@=?_.,".split(//)
      end
      def consolesafe_chars
        @consolesafe_chars ||= '+.-,_'.split(//)
      end
    end
  end
end
