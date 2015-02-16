module Crosstest
  class Psychic
    module Execution
      class TokenStrategy < DefaultStrategy
        def execute(*extra_args)
          template = File.read(absolute_file)
          # Default token pattern/replacement (used by php-opencloud) should be configurable
          token_handler = Tokens::RegexpTokenHandler.new(template, /["']\{(\w+)\}(["'])/, '\2\1\2')
          confirm_or_update_parameters(token_handler.tokens)
          content = token_handler.render(script.params)
          temporarily_overwrite(absolute_file, content) do
            super(*extra_args)
          end
        end

        private

        def temporarily_overwrite(file, content)
          backup_file = "#{file}.bak"
          logger.info("Temporarily replacing tokens in #{file} with actual values")
          FileUtils.cp(file, backup_file)
          File.write(file, content)
          yield
        ensure
          if File.exist? backup_file
            logger.info("Restoring #{file}")
            FileUtils.mv(backup_file, absolute_file)
          end
        end

        def logger
          psychic.logger
        end

        def file
          script.source_file
        end

        def absolute_file
          script.absolute_source_file
        end

        def backup_file
          "#{absolute_file}.bak"
        end

        def should_restore?(file, orig, timing = :before)
          return true if [timing, 'always']. include? opts[:restore_mode]
          if interactive?
            cli.yes? "Would you like to #{file} to #{orig} before running the script?"
          end
        end

        def backup_and_overwrite(file)
          backup_file = "#{file}.bak"
          if File.exist? backup_file
            if should_restore?(backup_file, file)
              FileUtils.mv(backup_file, file)
            else
              fail 'Please clear out old backups before rerunning' if File.exist? backup_file
            end
          end
          FileUtils.cp(file, backup_file)
        end
      end
    end
  end
end
