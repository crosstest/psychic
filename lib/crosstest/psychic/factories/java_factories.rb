module Crosstest
  class Psychic
    module Factories
      class GradleFactory < MagicTaskFactory
        TASK_PRIORITY = 6
        magic_file 'build.gradle'
        register_task_factory

        task :compile do
          'gradle assemble'
        end

        task :test do
          'gradle test'
        end

        task :integration do
          'gradle check'
        end

        task :bootstrap do
          # This is for projects using the maven plugin, may need to detect available
          # tasks w/ gradle install first
          'gradle install'
        end
      end

      class MavenFactory < MagicTaskFactory
        TASK_PRIORITY = 6
        magic_file 'pom.xml'
        register_task_factory

        task :compile do
          'mvn compile'
        end

        task :test do
          'mvn test'
        end

        task :integration do
          'mvn integration-test'
        end

        task :bootstrap do
          # Would compile or something else be more appropriate? install will run tests...
          'mvn install'
        end
      end

      class JavaFactory < ScriptFactory
        register_script_factory
        runs '**.java', 7

        def script(script)
          fully_qualified_name = file_to_fully_qualified_name(script.source_file)
          "java #{java_opts} #{fully_qualified_name}"
        end

        protected

        def file_to_fully_qualified_name(source_file)
          package = source_file.dirname.to_s
          package.gsub!('\\', '/')
          package.gsub!(%r{src/\w+/java}, '')
          package.gsub!('/', '.')
          package.gsub!(/\A\./, '')
          package = nil if package.empty?
          classname = source_file.basename(source_file.extname)
          [package, classname].compact.join('.')
        end

        def java_opts
          # Need a real way to choose/specify java options
          # Should run via or get classpath from gradle or maven
          '-classpath build/libs/*'
        end
      end
    end
  end
end
