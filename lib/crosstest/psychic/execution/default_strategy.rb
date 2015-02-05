module Crosstest
  class Psychic
    module Execution
      class DefaultStrategy < CommandTemplate
        attr_reader :script

        def initialize(script)
          @script = script
          @psychic = script.psychic
          super(script.psychic, build_command)
        end

        def execute(*extra_args)
          expand_parameters
          params = script.params
          command_params = { script: script.name, script_file: script.source_file }
          command_params.merge!(params) unless params.nil?
          super(command_params, *extra_args)
        end

        def build_command
          return @command if defined? @command

          script_factory = psychic.script_factory_manager.factories_for(script).last
          fail Crosstest::Psychic::ScriptNotRunnable, script if script_factory.nil?

          @command = script_factory.script(script)
          @command = @command.call if @command.respond_to? :call
          @command
        end

        def prompt(key)
          value = script.params[key]
          if value
            return value unless  psychic.opts[:interactive] == 'always'
            new_value = cli.ask "Please set a value for #{key} (or enter to confirm #{value.inspect}): "
            new_value.empty? ? value : new_value
          else
            cli.ask "Please set a value for #{key}: "
          end
        end

        def confirm_or_update_parameters(required_parameters)
          required_parameters.each do | key |
            script.params[key] = prompt(key)
          end if interactive?
        end

        def expand_parameters
          if script.params.is_a? String
            script.params = YAML.load(Tokens.replace_tokens(script.params, script.env))
          end
        end

        def interactive?
          psychic.interactive?
        end
      end
    end
  end
end
