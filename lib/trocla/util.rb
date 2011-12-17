class Trocla
  class Util
    class << self
      def random_str(length=12)
        (1..length).collect{|a| chars[rand(chars.size)] }.join.to_s
      end

      def salt(length=8)
        (1..length).collect{|a| normal_chars[rand(normal_chars.size)] }.join.to_s
      end

      private
      def chars
        @chars ||= normal_chars + special_chars
      end
      def normal_chars
        @normal_chars ||= ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
      end
      def special_chars
        @special_chars ||= "+*%/()@&=?![]{}-_.,;:".split(//)
      end
    end
  end
end
