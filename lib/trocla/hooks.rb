class Trocla
  module Hooks
    class Runner
      attr_reader :trocla
      def initialize(trocla)
        @trocla = trocla
      end

      def run(action, key, format, options)
        return unless hooks[action]
        hooks[action].each do |cmd|
          Trocla::Hooks.send(cmd, trocla, key, format, options)
        end
      end

      private

      def hooks
        @hooks ||= begin
          res = {}
          (trocla.config['hooks'] || {}).each do |action,action_hooks|
            res[action] ||= []
            action_hooks.each do |cmd,file|
              require File.join(file)
              res[action] << cmd
            end
          end
          res
        end
      end
    end
  end
end
