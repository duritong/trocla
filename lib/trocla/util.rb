require 'securerandom'
class Trocla
  class Util
    class << self
      def random_str(length=12,shellsafe=:undef)
        if shellsafe
          (1..length).collect{|a| safechars[SecureRandom.random_number(safechars.size)] }.join.to_s
        else
          (1..length).collect{|a| chars[SecureRandom.random_number(chars.size)] }.join.to_s
        end
      end

      def salt(length=8)
        (1..length).collect{|a| normal_chars[SecureRandom.random_number(normal_chars.size)] }.join.to_s
      end

      private
      def chars
        @chars ||= normal_chars + special_chars
      end
      def safechars
        @shellsafe ||= normal_chars + shellsafe_chars
      end
      def normal_chars
        @normal_chars ||= ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
      end
      def special_chars
        @special_chars ||= "+*%/()@&=?![]{}-_.,;:".split(//)
      end
      def shellsafe_chars
        @shellsafe_chars ||= "+%/@=?_.,:".split(//)
      end
    end
  end
end
