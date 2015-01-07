module Psychic
  class Runner
    class MagicTaskFactory
      include Psychic::Logger

      attr_reader :known_tasks, :tasks, :cwd, :env, :hints

      class << self
        def register_task_factory
          Psychic::Runner::TaskFactoryRegistry.register(self)
        end

        def magic_file_patterns
          @magic_file_patterns ||= []
        end

        def magic_file(pattern) # rubocop:disable Style/TrivialAccessors
          magic_file_patterns << pattern
        end

        def magic_env_vars
          @magic_env_vars ||= []
        end

        def magic_env_var(var)
          magic_env_vars << var
        end

        def known_tasks
          @known_tasks ||= []
        end

        def tasks
          @tasks ||= {}
        end

        def task(name, &block)
          name = name.to_s
          tasks[name] = block
          known_tasks << name
        end
      end

      def initialize(opts = {})
        @opts = opts
        init_attr(:cwd) { Dir.pwd }
        init_attr(:known_tasks) { self.class.known_tasks }
        init_attr(:tasks) { self.class.tasks }
        init_attr(:logger) { new_logger }
        init_attr(:env) { ENV.to_hash }
      end

      def task_for(task_name)
        tasks[task_name] if tasks.include? task_name
      end

      def build_task(task_name, *_args)
        task_name = task_name.to_s
        task = task_for(task_name)
        task = task.call if task.respond_to? :call
        fail Psychic::Runner::TaskNotImplementedError, task_name if task.nil?
        task
      end

      def active?
        self.class.magic_file_patterns.each do | pattern |
          return true unless Dir["#{@cwd}/#{pattern}"].empty?
        end
        self.class.magic_env_vars.each do | var |
          return true if ENV[var]
        end
        false
      end

      def known_task?(task_name)
        known_tasks.include?(task_name.to_s)
      end

      private

      def init_attr(var)
        var_name = "@#{var}"
        var_value = @opts[var]
        var_value = yield if var_value.nil? && block_given?
        instance_variable_set(var_name, var_value)
      end

      def init_attrs(*vars)
        vars.each do | var |
          init_attr var
        end
      end
    end
  end
end
