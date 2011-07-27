class Trocla
  class Util
    class << self
      def random_str(length=12)
        (1..length).collect{|a| chars[rand(chars.size)] }.join.to_s
      end
      
      private
      def chars
        @chars ||= (('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a) + "+*%/()@&=?![]{}-_.,;:<>".split(//)
      end
    end
  end
end