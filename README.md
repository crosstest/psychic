# Psychic

Psychic is a universal aliasing system for tasks and scripts. It provides a command-line tool to give humans easy-to-remember aliases for running tasks, and a API to give machines a standard way to interact with tasks and scripts across many projects.

It is part of the [Crosstest](https://github.com/crosstest/crosstest) suite of tools.

## Warning

Psychic is still pre-1.0 software that has **no** backwards compatibility guarantees until
the 1.0 release occurs!

## Installation

Psychic is installed as a gem. It's recommended that you install it with bunder. Add this to
you Gemfile:

```ruby
gem 'crosstest-psychic'
```

And run `bundle install`.

## Detection and Hints

Psychic itself is not a tool for implementing tasks, it's just a tool for detecting and aliasing
tasks and scripts that are handled by other tools. This is useful if you're dealing with a set of
projects and want to be able to use the same command alises for similar tasks, even if the actual
command to run the task differs.

This is similar to the approach taken by many CI systems, which map commands to stages of a lifecycle
and attempt to automatically detect appropriate commands if they are not explicitly mapped. The
[travis-build](https://github.com/travis-ci/travis-build) project is an example of this. It gives you
commands like `travis run install`, which will run the install commands for the project. Those commands
may be specified in your `travis.yml`, but if they aren't than it will examine your project and attempt
to choose an appropriate install command.

Psychic is similar. It will first look in `psychic.yaml` to see if you have explicitly mapped an alias to a command, and then it will look examine your project and attempt to infer an appropriate command. What makes Psychic different than travis-build is that it's designed as a more generic, standalone tool and API. It aims to detect and use the same idiomatic tools as Travis, but it is easier to install and use, does not perform optimizations that are appropriate on CI servers but may surprise developers, and offers some features that are useful in development environments but not on CI servers (like the `--interactive` mode).

## API

Psychic has a simple API. You simply create a Psychic instance and then ask it for tasks or scripts:

```ruby
psychic = Crosstest::Psychic.new

# Find and execute the bootstrap task
psychic.task('bootstrap').execute

# Find a runner and execute a specific script
# Psychic will figure out if it needs to do things
# like run `bundle exec` or `javac`.
psychic.script('samples/quine.rb').execute

# You can also find scripts by alias or by loosely matching
# the name.
psychic.script('hello world').source_file
# => 'src/main/java/HelloWorld.java'
```

See the full [API Documentation](http://www.rubydoc.info/github/crosstest/psychic) for more.

## CLI Usage

It's easy to list the available commands:

```
$ bundle exec psychic help
Scripts commands:
  psychic bootstrap       # Executes the bootstrap task
  psychic help [COMMAND]  # Describe available commands or one specific command
  psychic list            # List known tasks or scripts
  psychic script <name>   # Executes a script
  psychic show            # Show details about a task or script
  psychic task <name>     # Executes any task by name
```

### Tasks

It's easy to print or run a task:

```
$ bundle exec psychic bootstrap --print
bundle install

$ bundle exec psychic bootstrap
I, [2015-01-30T14:28:06.940072 #39505]  INFO -- :        Executing: bundle install
I, [2015-01-30T14:28:07.745404 #39505]  INFO -- :        Resolving dependencies...
I, [2015-01-30T14:28:07.749574 #39505]  INFO -- :        Using ast 2.0.0
I, [2015-01-30T14:28:07.749677 #39505]  INFO -- :        Using parser 2.2.0.2
I, [2015-01-30T14:28:07.749709 #39505]  INFO -- :        Using astrolabe 1.3.0
...
I, [2015-01-30T14:28:07.939301 #39505]  INFO -- :        Your bundle is complete!
I, [2015-01-30T14:28:07.939427 #39505]  INFO -- :        Use `bundle show [gemname]` to see where a bundled gem is installed.
```

#### Custom tasks

There are built-in aliases that correspond to common commands in a CI lifecycle, like `bootstrap` above. Psychic will usually find an appropriate command for these tasks in any project.

Psychic can also custom tasks that are not part of the default CI lifecycle and may not even exist in all projects. This could be anything from a fairly common name like `lint`, to something like `generate_report_for_my_boss`.

You can run these with the `psychic task <name>` command:
```
~/ruby $ bundle exec psychic task lint --print
bundle exec rubocop -D

~/java $ bundle exec psychic task lint --print
gradle checkstyleMain

~/python $ bundle exec psychic task lint --print
./scripts/lint.sh
```

#### travis-build integration

Psychic can delegate tasks that correspond to the travis lifecycle to travis-build if it is installed. This isn't enabled by default, because the travis-build uses optimizations for running on CI servers that could cause confusion in developer environments, like using sticky bundler flags like `--deployment`.

If you the working directory contains a .travis.yml file and you have travis-build installed you can delegate to it with the `--travis` option:

```
$ bundle exec psychic task bootstrap --print --travis
travis run --skip-version-check install
```

#### scripts/* integraiton

ThoughtBot, GitHub and others use a [bootstrap consistency pattern](http://wynnnetherland.com/linked/2013012801/bootstrapping-consistency) to provide "a consistent user experience to get from zero to productive on any new project". The scripts used vary but common examples are:
- Bootstrapping via `bin/setup` or `script/bootstrap`
- Running tests via `script/test` and/or `script/cibuild`

Psychic has built-in support for these patterns, and will automatically map anything in scripts/* to a task alias. It will also select a platform appropriate script, like `bootstrap.sh` for Linux and `bootstrap.ps` for Windows.

### Scripts

Psychic also supports running scripts, including ones that require input. You just use the `script` command, along with either the path to a script, or an alias for a script. This is useful for running code samples that are implemented in multiple languages:

```
~/java $ bundle exec psychic script src/main/java/HelloWorld.java
I, [2015-01-30T15:01:44.417646 #42722]  INFO -- :        Executing: ./scripts/run_script.sh src/main/java/HelloWorld.java
I, [2015-01-30T15:01:53.231440 #42722]  INFO -- :        Hello, world!

~/java $ bundle exec psychic script "hello world"
I, [2015-01-30T15:00:32.099182 #42637]  INFO -- :        Executing: ./scripts/run_script.sh src/main/java/HelloWorld.java
I, [2015-01-30T15:00:43.497285 #42637]  INFO -- :        Hello, world!

~/ruby $ bundle exec psychic script "hello world"
I, [2015-01-30T14:59:40.349071 #42524]  INFO -- :        Executing: bundle exec ruby katas/hello_world.rb
I, [2015-01-30T14:59:42.750909 #42524]  INFO -- :        Hello, world!
```

#### Input

Work in progress! This describes a feature that is still under development. This section describes the plan for handling input, but these strategies are not all implemented yet.

Psychic can bind key/value pairs to input for scripts. There are a few strategies planned for mapping input:
- Passing them as environment variables
- Passing them as key-value parameters to the command (e.g. `--foo=bar`)
- Performing a token-replacement on a script with [Mustache](mustache.github.io) style templates
- Passing as positional arguments to scripts with a templated command in `psychic.yaml`

The command `psychic show script` will show you what tokens have been detected for a script:

```
$ bundle exec psychic show script "create server"
Script Name:                          create server
Tokens:
- authUrl
- username
- apiKey
- region
- serverName
- imageId
- flavorId
Source File:                          Compute/create_server.php
```

#### Interactive Mode

You can run scripts interactive mode with the `--interactive` flag. Psychic will prompt you to provide values for input tokens. If you just the use the `--interactive` flag than it will prompt you for values that are not assigned a value. If you use `--interactive=always` then it will ask you to confirm or overwrite existing values as well:

```
$ bundle exec psychic script "create server" --interactive=always
Please set a value for authUrl:  http://localhost:5000/
Please set a value for username (or enter to confirm "my_user"):
Please set a value for apiKey (or enter to confirm "1234abcd"):
Please set a value for region (or enter to confirm "ORD"):
Please set a value for serverName (or enter to confirm "my_server"):
Please set a value for imageId (or enter to confirm 45678):
Please set a value for flavorId (or enter to confirm 12345):
Executing: php Compute/create_server.php
```

#### Additional command-line arguments and parameters

You can also pass additional arguments to your the task or script that Psychic is going to run. This is generally a bad idea Psychic doesn't standardize the flags so the commands will no longer be portable, but it can be useful for passing simple flags like `--debug` or `--verbose`.

You use the end of options delimiter (` -- `) to mark the end of arguments that should be parsed by Psychic and the beginning of what should be passed, as-is, to the command Psychic invokes:

```
# Task without additional arguments
~/ruby $ bundle exec psychic task lint
I, [2015-01-30T17:21:10.564551 #46122]  INFO -- :        Executing: bundle exec rubocop -D

# Task plus the --help flag
$ bundle exec psychic task lint -- --help
I, [2015-01-30T17:24:40.084622 #46319]  INFO -- :        Executing: bundle exec rubocop -D --help
I, [2015-01-30T17:24:41.035289 #46319]  INFO -- :        warning: parser/current is loading parser/ruby21, which recognizes
I, [2015-01-30T17:24:41.035395 #46319]  INFO -- :        warning: 2.1.5-compliant syntax, but you are running 2.1.4.
I, [2015-01-30T17:24:41.359328 #46319]  INFO -- :        Usage: rubocop [options] [file1, file2, ...]
I, [2015-01-30T17:24:41.359413 #46319]  INFO -- :                --only [COP1,COP2,...]       Run only the given cop(s).
I, [2015-01-30T17:24:41.359449 #46319]  INFO -- :                --only-guide-cops            Run only cops for rules that link to a
I, [2015-01-30T17:24:41.359478 #46319]  INFO -- :                                             style guide.
...
```

## Acknowledgements

Portions of the Crosstest projects were based on [rocco](https://github.com/rtomayko/rocco) projects, which was a port of [docco](https://github.com/jashkenas/docco).

A lot of code, and the style of the CLI tools, are based on heavily modified code adapted from [test-kitchen](https://github.com/test-kitchen/test-kitchen).

## Related projects

### Skeptic

The [Skeptic](https://github.com/crosstest/skeptic) project is a companion to Psychic that tests the uses Psychic's script runner to test sample code. It captures and validates the output the exit code and output of the process, but can also capture additional data through "spies" like looking for HTTP calls it expects to see or files that should be created. So it let's you write assertions and reports on the behavior of code that's executed via Psychic.

### Crosstest

The [crosstest](https://github.com/crosstest/crosstest) project is for running tasks or tests across multiple projects. It uses Psychic (and Skeptic) in order to run the task in teach project, and then consolidates all of the results and produces reports.

## Contributing

It's easy to add most task runners to Psychic, we just need you to map the commands. See [CONTRIBUTING.md](CONTRIBUTING.md) for more details.
