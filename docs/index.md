# Psychic::Runner

Psychic runs anything.

## What is Psychic

Psychic is a project to help developers that work on many different projects. It
provides a unified interface for running tasks so you don't need to remember a
bunch of project specific commands.

Psychic provides command aliases so that a command like `psychic bootstrap`
will invoke a similiar task in any project, but the actual command invoked will vary.
It might end up calling `bundle install`, `npm install` `./scripts/boostrap.sh` or some
other command.

Psychic provides a common set of alises for common tasks but also allows you to define
custom tasks across different projects, so you could have cross-project commands like
`metrics` or `documentation`.

## Why?

Psychic exists to provide a common interface for tasks to build, test, and analyze projects while still allowing (or even encouraging) projects to use idiomatic patterns for their particular language. This makes it easy for new contributors to join a project because it follows the "principal of least astonishment", while also providing a consistent interface for tools to build, test or analyze any project.

The [bootstrap consistency pattern](http://wynnnetherland.com/linked/2013012801/bootstrapping-consistency) is an example of that. It aims to provide "a consistent user experience to get from zero to productive on any new project". Similarly, Travis-CI gives you a consistent interface to test any software project. The command `travis run` will always build and test a project.

Omnitest is an attempt to make a more generic framework for creating consistent user experiences across projects. That experienec can be "getting from zero to productive" like the bootstrap consistency pattern, "testing a change" like Travis-CI, or even something like "generating end of sprint reports" or "generating and previewing documentation".

In fact, the reason the project is called "psychic" is because it's supposed to seem like it's reading your mind. When you ask it to do something, like "bootstrap" a project, it should seem like it just magically picks the correct command to run. The project is actually more of a fraud than a clairvoyant - it just uses "[hot](http://en.wikipedia.org/wiki/Hot_reading)" and "[cold](http://en.wikipedia.org/wiki/Cold_reading)" reading tricks to pick the correct command.

### Psychic vs scripts/*

ThoughtBot, GitHub and others use a [bootstrap consistency pattern](http://wynnnetherland.com/linked/2013012801/bootstrapping-consistency) to provide "a consistent user experience to get from zero to productive on any new project". The scripts used vary but common examples are:
- Bootstrapping via `bin/setup` or `script/bootstrap`
- Running tests via `script/test` and/or `script/cibuild`

Psychic's goals are similar but it's scope is broader, as explained above. Psychic will detect the scripts/* pattern and delegate task commands to it, so `psychic task bootstrap` will run `scripts/bootstrap.sh` if it exists. If you have both `bootstrap.sh` and `boostrap.ps1` (for Windows) psychic will choose the appropriate script for your platform.

The difference is that if you try to run a task for psychic that doesn't have a script Psychic will continue looking for other ways to run that task. For example, if you have a `scripts/bootstrap.sh` and `Rakefile` that defines `lint` task, then `psychic bootstrap` will run `scripts/bootstrap.sh`, while `psychic lint` will run `rake lint`.

### Psychic vs Travis-Build

The goals of psychic are also similar to travis-build, and psychic will delegate supported tasks to travis-build if it is installed. Even if it isn't installed, Psychic aims to be as compatible as possible with travis-build, so a command like `psychic task install` behave a lot like `travis run install`.

Note that travis-build is not installed as a normal gem or Psychic would just depend on it. If you want psychic to delegate to travis-build you need to [install it as a CLI extension](https://github.com/travis-ci/travis-build#use-as-addon-for-cli).

#### Scope
Psychic's scope is broader, so there are things you could do with psychic that wouldn't make sense to run on Travis-CI. For example, you could setup a command like `psychic wip`, that would show your work in progress for any given project. The behavior would be project specific, but could include things like:
- Listing your local branches that haven't been merged
- Listing pull requests that are assigned to you
- Issues that are assigned to you
- Display `what_im_working_on.txt`

The command could be setup so it would display a WIP report for any project, even if some projects are getting info from your local git branches, other from GitHub, and others from issue trackers like JIRA, Launchpad, or Mingle. This command obviously doesn't make sense on Travis-CI, especially if it's only showing the work in progress for a current developer, but could be very useful if you want to quickly review your WIP across several projects. That's what the [omnitest](https://github.com/omnitest/omnitest) tool's [crosstasking](https://github.com/omnitest/omnitest#crosstasking-via-psychic) feature is designed to do.

#### Features

This is one of the reasons why psychic was created as a new project rather than as enhancements to travis-build. In general, Psychic aims to provide a simpler API that is less coupled with Travis. The major differences between Psychic and travis-build are:
- Psychic is distributed as a gem that can be used as a library or a standalone CLI. Travis-build is a
travis CLI extension that is not distributed as a gem.
- Psychic as a simple API for running tasks by alias. The travis-build API is tightly coupled with a travis-configuration object.
- Psychic just provides task aliases and inference. It does not provide environment setup, like fetching projects from version control or driving environment managers like rvm or virtualenv. Those actions should be done before invoking psychic.
- Psychic does not contain travis-specific features like integration with travis's caching system.

## Psychic Commands

### Tasks

Psychic supports both built-in and custom tasks. You should be able to use built-in tasks in virtually any project, even projects that weren't setup for psychic, because these tasks are mapped to common actions of commonly used tools.

#### Built-in Tasks

The `bootstrap` task is an example of a built-in task. If you run `psychic bootstrap` it will setup your project. It detects tools or patterns that are commonly used to setup projects and will choose an appropriate command for that tool. So it may run something like `bundle install`, `npm install`, or `scripts/bootstrap.sh`, depending on your project.

The built-in tasks are all mapped to top-level commands, so you can see them by running `psychic help`.

#### Custom Tasks

Psychic can also run custom tasks. You can list all known tasks, including custom tasks, with the command `psychic list tasks`. If you run with the `--verbose` flag it will show the command that would be run.

This list will include any custom tasks mapped to a command in `psychic.yaml`. Psychic will also try to detect known tasks from any tool that can print out a list of documented tasks, like Rake (via `rake --tasks` ), Grunt (via `grunt --help`) or NPM (via `npm run`). This is only partially supported, because not all tools support listing tasks, and even the ones that do rarely have an option for machine-readable output or an option like git's `--porcelain` (to "give the output in an easy-to-parse format for scripts", which will "remain stable across versions regardless of user configuration").

You can run a custom task via `psychic task <task_name>`. So if you have defined a `lint` task in a tool that supports autodetection, or defined the task in `psychic.yaml`, then you can run it with `psychic task lint`.

```sh
 bundle exec psychic task lint
I, [2015-01-15T13:01:09.752242 #59850]  INFO -- : Executing bundle exec rubocop -D
I, [2015-01-15T13:01:10.595926 #59850]  INFO -- : warning: parser/current is loading parser/ruby21, which recognizes
I, [2015-01-15T13:01:10.596019 #59850]  INFO -- : warning: 2.1.5-compliant syntax, but you are running 2.1.4.
I, [2015-01-15T13:01:11.142419 #59850]  INFO -- : Inspecting 2 files
I, [2015-01-15T13:01:11.142526 #59850]  INFO -- : ..
I, [2015-01-15T13:01:11.142553 #59850]  INFO -- :
I, [2015-01-15T13:01:11.142576 #59850]  INFO -- : 2 files inspected, no offenses detected
```

You can also pass additional arguments to the command after the end of options delimiter (`--`). This is useful for passing flags like `--debug`, `--verbose` or `--help`, though there is no guarantee that any of these flags will work (even `--help`) will work for a task.

```sh
$ bundle exec psychic task lint -- --debug
I, [2015-01-15T13:06:11.456547 #60908]  INFO -- : Executing bundle exec rubocop -D --debug
I, [2015-01-15T13:06:12.288424 #60908]  INFO -- : warning: parser/current is loading parser/ruby21, which recognizes
I, [2015-01-15T13:06:12.289181 #60908]  INFO -- : warning: 2.1.5-compliant syntax, but you are running 2.1.4.
I, [2015-01-15T13:06:12.689274 #60908]  INFO -- : For /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/ruby: configuration from /Users/Thoughtworker/repos/rackspace/polytrix/.rubocop.yml
I, [2015-01-15T13:06:12.689343 #60908]  INFO -- : Inheriting configuration from /Users/Thoughtworker/repos/rackspace/polytrix/.rubocop_todo.yml
I, [2015-01-15T13:06:12.689372 #60908]  INFO -- : Default configuration from /opt/boxen/rbenv/versions/2.1.4/lib/ruby/gems/2.1.0/gems/rubocop-0.28.0/config/default.yml
I, [2015-01-15T13:06:12.689396 #60908]  INFO -- : Inheriting configuration from /opt/boxen/rbenv/versions/2.1.4/lib/ruby/gems/2.1.0/gems/rubocop-0.28.0/config/enabled.yml
I, [2015-01-15T13:06:12.689421 #60908]  INFO -- : Inheriting configuration from /opt/boxen/rbenv/versions/2.1.4/lib/ruby/gems/2.1.0/gems/rubocop-0.28.0/config/disabled.yml
I, [2015-01-15T13:06:12.689447 #60908]  INFO -- : Inspecting 2 files
I, [2015-01-15T13:06:12.689487 #60908]  INFO -- : Scanning /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/ruby/Gemfile
I, [2015-01-15T13:06:12.689514 #60908]  INFO -- : .Scanning /Users/Thoughtworker/repos/rackspace/polytrix/samples/sdks/ruby/katas/hello_world.rb
I, [2015-01-15T13:06:12.689534 #60908]  INFO -- : .
I, [2015-01-15T13:06:12.689553 #60908]  INFO -- :
I, [2015-01-15T13:06:12.689574 #60908]  INFO -- : 2 files inspected, no offenses detected
I, [2015-01-15T13:06:12.689595 #60908]  INFO -- : Finished in 0.04216 seconds
```

### Code Samples

Psychic also has features to detect and run a code sample by alias, just like it runs tasks by an alias. This gets more complicated and might be split into a separate gem in the future, so we'll leave that for a separate doc.

## Related projects

### Skeptic

The [Skeptic](https://github.com/omnitest/skeptic) project is a companion to Psychic that tests the results code samples via Psychic. It captures and validates the output the exit code and output of the process, but can also capture additional data through "spies" like looking for HTTP calls it expects to see or files that should be created. So it let's you write assertions and reports on the behavior of code that's executed via Psychic.

### Omnitest

The [omnitest](https://github.com/omnitest/omnitest) project is for running tasks or tests across multiple projects. It uses Psychic (and Skeptic) in order to run the task in teach project, and then consolidates all of the results and produces reports.
