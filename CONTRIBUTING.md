# Contributing

## Adding support for new task tools

It's fairly easy to contribute support for new task runners to Psychic. Most can be implemented using the `MagicTaskFactory` class, which will look for a magic file to indicate a certain tool is being used, and then simply maps the tasks.

Here's an example for Gradle:

```ruby
class GradleFactory < MagicTaskFactory
  TASK_PRIORITY = 6
  magic_file 'build.gradle'
  register_task_factory

  task :compile do
    'gradle assemble'
  end

  task :unit do
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
```

You can also override or implement your own class with the `#active?`, `#priority_for_task(task)`, `#known_tasks` and `#task(alias)` methods. See the API documentation details.

## Adding support for new types of scripts

Adding support for different types of scripts is also fairly easy. You can either implement the methods `#active?`, `#known_scripts`, `#priority_for_script(script_object)` and `#script(script_object)`, or you can subclass from ScriptFactory and in which case you'll just need to define the patterns the class runs and the `#script(script_object)` method. Here's an example for running Java classes:

```ruby
class RubyFactory < ScriptFactory
  register_script_factory
  runs '**.rb', 8

  def script(_script)
    cmd = bundler_active? ? 'bundle exec ' : ''
    cmd << 'ruby {{script_file}}'
  end

  protected

  def bundler_active?
    psychic.task_factory_manager.active? BundlerTaskFactory
  end
end
```

## Other

If you're interested in adding other features or support for other types of tools, please just create an issue on GitHub and we'll help you figure out the best way to proceed.
