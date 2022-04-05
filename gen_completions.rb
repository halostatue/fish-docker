#!/usr/bin/env ruby
# frozen_string_literal: true

# require 'byebug'
require "pathname"
require "set"
require "shellwords"

def log(message)
  warn message
end

NO_SUBCOMMAND_FUNCTION_NAME = "_halostatue_fish_%s_no_subcommand"

# A class to help with subcommand definition.
class Subcommand
  attr_reader :command, :description, :args, :switches

  def initialize(command, description, args, switches)
    @command = command
    @description = description
    @args = args
    @switches = switches
  end

  def generate(docker, arg_builder)
    [
      "# #{command}",
      build_help(docker),
      *build_switches(docker),
      *build_args(docker, arg_builder),
      "\n"
    ]
  end

  private

  def build_help(docker)
    Completion.generate { |completion|
      completion.command(docker.binary)
      completion.cond(:no_subcommand)
      completion.arg(command)
      completion.description(description)
    }
  end

  def build_switches(docker)
    switches.map { |switch|
      switch.completion.cond(:subcommand, command)
      switch.generate(docker.binary)
    }
  end

  def build_args(_docker, arg_builder)
    uniq = Set.new
    args.each do |arg|
      m = /\[(.+)\.\.\.\]/.match(arg)
      arg = m[1] if m
      uniq.merge(arg.split("|"))
    end

    uniq.map { |arg| arg_builder.call(self, arg) }.compact
  end
end

# A helper class to generate a fish completion command-line.
class Completion
  def self.generate(&block)
    new.tap(&block).generate
  end

  def initialize(docker: nil, command: nil, description: nil)
    @docker = docker
    @command = command
    @description = description
    @condition = []
    @short_options = []
    @long_options = []
    @old_options = []
    @arguments = []
    @keep = @force_files = @no_files = @required = @exclusive = false
    @wraps = []
  end

  def command(value = :not_provided)
    get_or_set(:@command, value)
  end

  def docker(value = :not_provided)
    get_or_set(:@docker, value)
  end

  def description(value = :not_provided)
    get_or_set(:@description, value)
  end

  # -n or --condition specifies a shell command that must return 0 if the
  # completion is to be used. This makes it possible to specify completions
  # that should only be used in some cases.
  def cond(statement, *args)
    args =
      case statement
      when :no_subcommand
        NO_SUBCOMMAND_FUNCTION_NAME % (command || docker.binary).tr("-", "_")
      when :subcommand
        args.map { |c| "__fish_seen_subcommand_from %{command}" % {command: c} }
      else
        condition << args.empty? ? statement : "#{statement} #{args.join(" ")}"
      end

    push(:@condition, args)
  end

  # -w WRAPPED_COMMAND or --wraps=WRAPPED_COMMAND causes the specified command
  # to inherit completions from the wrapped command (See below for details).
  def wraps(command)
    push(:@wraps, command)
  end

  # arg values may be strings a hash of the shape:
  # { command: COMMAND, args: args }
  #
  # -a OPTION_ARGUMENTS or --arguments=OPTION_ARGUMENTS adds the specified
  # option arguments to the completions list.
  def arg(*values)
    push(:@arguments, values)
  end

  # -k or --keep-order preserves the order of the OPTION_ARGUMENTS specified
  # via -a or --arguments instead of sorting alphabetically.
  def keep
    set(:@keep)
  end

  # -f or --no-files specifies that the options specified by this completion
  # may not be followed by a filename. Will be ignored if +force_files+ has
  # been set.
  def no_files
    set(:@no_files) unless @force_files
  end

  # -F or --force-files specifies that the options specified by this completion
  # may be followed by a filename. Overrides +no_files+.
  def force_files
    set(:@no_files, to: false)
    set(:@force_files)
  end

  # -r or --require-parameter specifies that the options specified by this
  # completion always must have an option argument, i.e. may not be followed by
  # another option.
  def required
    set(:@required)
  end

  # -x or --exclusive implies both -r and -f.
  def exclusive
    set(:@exclusive)
  end

  # -s SHORT_OPTION or --short-option=SHORT_OPTION adds a short option to the
  # completions list.
  #
  # Short options, like '-a'. Short options are a single character long, are
  # preceded by a single hyphen and may be grouped together (like '-la', which
  # is equivalent to '-l -a'). Option arguments may be specified in the
  # following parameter ('-w 32') or by appending the option with the value
  # ('-w32').
  def short(value)
    push(:@short_options, value.sub(/^-+/, ""))
  end

  # -l LONG_OPTION or --long-option=LONG_OPTION adds a GNU style long option to
  # the completions list.
  #
  # GNU style long options, like '--colors'. GNU style long options can be more
  # than one character long, are preceded by two hyphens, and may not be
  # grouped together. Option arguments may be specified in the following
  # parameter ('--quoting-style shell') or by appending the option with a '='
  # and the value ('--quoting-style=shell'). GNU style long options may be
  # abbreviated so long as the abbreviation is unique ('--h') is equivalent to
  # '--help' if help is the only long option beginning with an 'h').
  def long(value)
    push(:@long_options, value.sub(/^-+/, ""))
  end

  # -o LONG_OPTION or --old-option=LONG_OPTION adds an old style long option to
  # the completions list (See below for details).
  #
  # Old style long options, like '-Wall'. Old style long options can be more
  # than one character long, are preceded by a single hyphen and may not be
  # grouped together. Option arguments are specified in the following parameter
  # ('-ao null').
  def old(value)
    push(:@old_options, value.sub(/^-+/, ""))
  end

  def generate(command = nil)
    [
      *generate_base(command),
      generate_cond,
      *generate_wraps,
      generate_args,
      *generate_flags,
      *generate_options
    ].compact.join(" ")
  end

  private

  def get_or_set(var, value)
    if value == :not_provided
      instance_variable_get(var)
    else
      instance_variable_set(var, value)
    end
  end

  def push(var, values)
    instance_variable_get(var).push(*Array(values))
  end

  def set(var, to: true)
    instance_variable_set(var, to)
  end

  def generate_base(command)
    %W[complete --command #{command || @command}].tap { |base|
      base.push("--description", @description.gsub(Regexp.escape(ENV["HOME"]), "~").inspect) if @description
    }
  end

  def generate_cond
    "--condition '#{@condition.join("; and")}'" unless @condition.empty?
  end

  def generate_wraps
    @wraps.map { |wrap| %W[--wraps #{wrap}] } unless @wraps.empty?
  end

  def generate_args
    return if @arguments.empty?

    args = @arguments.map { |e|
      e.kind_of?(Hash) ? "(#{e[:command]} #{Array(e[:args]).join(" ")})" : e
    }.join("\n")

    "--arguments '#{args}'"
  end

  def generate_flags
    [].tap { |flags|
      flags << "--keep-order" if @keep
      flags << "--no-files" if @no_files
      flags << "--force-files" if @force_files
      flags << "--require-parameter" if @required
      flags << "--exclusive" if @exclusive
    }
  end

  def generate_options
    @short_options.map { |o| "--short-option %{option}" % {option: o} } +
      @long_options.map { |o| "--long-option %{option}" % {option: o} } +
      @old_options.map { |o| "--old-option %{option}" % {option: o} }
  end
end

# A helper class to create a completion object for a command switch.
class Switch
  attr_reader :completion

  def initialize(shorts, longs, description, metavar, docker)
    @completion = Completion.new(description: description, docker: docker)

    shorts.each do |short| @completion.short(short) end
    longs.each do |long| @completion.long(long) end

    metavar = Array(metavar).compact

    return if metavar.empty?

    if metavar.grep(/FILE|PATH/).empty?
      @completion.exclusive
    else
      @completion.required
    end
  end

  def generate(command)
    @completion.generate(command)
  end
end

# Building a Docker command line.
class DockerCmdLine
  attr_reader :docker_path, :parts

  def binary
    "docker"
  end

  def initialize(path)
    @docker_path = path
    log("Building parts for #{binary}")
    @parts = build_parts(output("help"))
  end

  def common_options
    @common_options ||= begin
      log("Parsing switches for #{binary}")
      parse_switches(@parts).each { |s|
        s.completion.cond(:no_subcommand)
      }
    end
  end

  def subcommands
    @subcommands ||= begin
      log("Building subcommands for #{binary}")
      subcommand_groups.reduce([]) { |acc, group|
        acc + parse_subcommands(@parts, group)
      }
    end
  end

  private

  def subcommand_groups
    %w[commands management\ commands]
  end

  def build_parts(lines)
    parts = Hash.new { |h, k| h[k] = [] }
    part = nil

    lines.each do |line|
      if line =~ /usage:(.+)$/i
        parts["usage"] << Regexp.last_match(1)
      elsif line =~ /(.*):$/
        part = Regexp.last_match(1).downcase
      elsif line =~ /^$/
        part = nil
      elsif part
        parts[part] << line
      end
    end

    parts
  end

  def output(*args)
    cmd = [File.join(docker_path, binary), *args]

    # docker returns non-zero exit code for some help commands so can't use
    # subprocess.check_output here

    %x(#{cmd.shelljoin} 2>&1).split($/)
  end

  def parse_switches(parts)
    parts["options"].map { |line| parse_switch(line) }.compact
  end

  def parse_switch(line)
    line = line.strip
    return nil unless line.match?(/  /)

    opt, description = line.split(/  +/, 2)
    switches = opt.split(/, /)
    metavar = nil

    # handle arguments with metavar
    # Options:
    # -f, --file FILE

    switches.each_with_index do |switch, i|
      next unless switch.match?(" ")

      opt, metavar = switch.split(" ", 2)

      # Handle incorrectly specified PATHs
      metavar =
        case opt
        when "--tlscacert", "--tlscert", "--tlskey"
          "FILE"
        when "--config"
          "PATH"
        else
          metavar
        end

      switches[i] = opt
    end

    shorts = switches.reject { |e| e.start_with?("--") }.map { |e| e.sub(/^-+/, "") }
    longs = switches.filter { |e| e.start_with?("--") }.map { |e| e.sub(/^-+/, "") }

    Switch.new(shorts, longs, description, metavar, self)
  end

  def parse_subcommands(parts, name)
    parts[name].map { |line| parse_subcommand(line) }.compact
  end

  def parse_subcommand(line)
    return unless line.start_with?("  ")

    build_subcommand(*line.strip.split(/\s+/, 2))
  end

  def build_subcommand(command, description)
    log("Building #{binary} #{command}")
    command.gsub!(/\*$/, "")
    lines = output("help", command)
    parts = build_parts(lines)
    usage = parts["usage"]&.first&.gsub(/ \| /, "|")

    raise "Can't find Usage in command #{command.inspect}" unless usage

    args = usage.split(/\s+/)[3..-1].reject { |arg| arg.upcase == "[OPTIONS]" }

    case command
    when "push", "pull"
      args = %w[REPOSITORY|IMAGE]
    when "images"
      args = %w[REPOSITORY]
    end

    switches = parse_switches(parts)

    Subcommand.new(command, description, args, switches)
  rescue
    puts lines
    puts
    puts "usage: #{usage.inspect}"
    puts "args: #{args.inspect}"
    raise
  end
end

# Operating the command-line for `docker-compose`.
class DockerComposeCmdLine < DockerCmdLine
  def binary
    "docker-compose"
  end

  def subcommand_groups
    %w[commands]
  end
end

# Common code for fish completion generation.
class BaseFishGenerator
  FUNCTION = <<~FUNCTION
    function %{function}
        for i in (commandline -opc)
            contains -- $i %{commands}; and return 1
        end
        return 0
    end
  FUNCTION

  attr_reader :docker

  def initialize(docker)
    @docker = docker
  end

  def header_text
    <<~TEXT
      # #{docker.binary} completions for fish shell
      #
      # This file is generated by `gen_completions.rb` from
      # https://github.com/halostatue/fish-docker

      complete -e -c #{docker.binary}

      # Completions currently supported:
    TEXT
  end

  def function(commands)
    FUNCTION % {
      function: NO_SUBCOMMAND_FUNCTION_NAME % docker.binary.tr("-", "_"),
      commands: commands.join(" ")
    }
  end

  # Generate fish completions definitions for docker
  def generate
    puts header, "\n", common_options, "\n", subcommands
  end

  def header
    [
      header_text,
      "\n",
      function(docker.subcommands.map(&:command).sort),
      "\n"
    ].compact.uniq
  end

  def common_options
    switches = docker.common_options.map { |switch|
      switch.generate(docker.binary)
    }

    [
      "# common options",
      *switches,
      "\n"
    ]
  end

  def subcommands
    [
      "# subcommands",
      *docker.subcommands.flat_map { |sub| sub.generate(docker, method(:process_subcommand_arg)) },
      "\n"
    ]
  end

  def process_subcommand_arg(_sub, _arg)
    nil
  end
end

# Generate a completion for `docker`.
class DockerFishGenerator < BaseFishGenerator
  def header_text
    super + <<~TEXT
      # - parameters
      # - commands
      # - containers
      # - images
      # - repositories
      #
      # Management commands (commands with subcommands) are not yet supported.
    TEXT
  end

  def process_subcommand_arg(sub, arg)
    Completion.generate { |completion|
      completion.command(docker.binary)
      completion.cond(:subcommand, sub.command)

      case arg
      when "CONTAINER", "[CONTAINER...]"
        select =
          case sub.command
          when "start", "rm"
            "stopped"
          when "commit", "diff", "export", "inspect", "cp"
            "all"
          else
            "running"
          end

        completion.arg(command: "_halostatue_fish_docker_print_containers", args: select)
        completion.description("Container")
        completion.exclusive
      when "CONTAINER:SRC_PATH"
        completion.arg(command: "_halostatue_fish_docker_print_containers", args: "all :")
        completion.description(arg)
        completion.exclusive
      when "IMAGE", "SOURCE_IMAGE", "TARGET_IMAGE"
        completion.arg(command: "_halostatue_fish_docker_print_images")
        completion.description("Image")
        completion.exclusive
      when "REPOSITORY", "[REPOSITORY[:TAG]]"
        completion.arg(command: "_halostatue_fish_docker_print_repositories")
        completion.description("Repository")
        completion.exclusive
      when "PATH", "FILE", "DEST_PATH", "file"
        completion.description(arg)
        completion.required
        completion.force_files
      when "-"
        completion.arg("-")
        completion.description("STDIN")
        completion.exclusive
      else
        completion.description(arg)
        completion.exclusive
      end
    }
  end
end

# Generate documentation for `docker-compose`.
class DockerComposeFishGenerator < BaseFishGenerator
  def header_text
    super + <<~TEXT
      # - parameters
      # - commands
      # - services
    TEXT
  end

  def process_subcommand_arg(sub, arg)
    return unless %w(SERVICE [SERVICE...]).include?(arg)

    Completion.generate { |completion|
      completion.command(docker.binary)
      completion.cond(:subcommand, sub.command)
      completion.no_files

      completion.arg(command: "_halostatue_fish_docker_print_compose_services")
      completion.description("Service")
    }
  end
end

# Run the generator. This will be changing because we should always run both
# `docker` and `docker-compose` generation and write them to the correct
# location.
class Runner
  def self.run(binary)
    new(binary).run
  end

  def initialize(binary)
    @binary = validate(binary&.downcase)
    @docker_path = find_docker_path(@binary)
    @generator = generator_for(@binary)
  end

  def run
    @generator.generate
  end

  private

  def validate(binary)
    raise "Unknown binary #{binary.inspect}" unless %w[docker docker-compose].include?(binary)

    @binary = binary
  end

  def find_docker_path(binary)
    docker_path = ENV["PATH"].split(/:/).find { |path|
      exe = File.join(path, binary)
      File.exist?(exe) || File.exist?("#{exe}.exe")
    }

    return docker_path if docker_path

    raise "No #{binary.inspect} found in $PATH."
  end

  def generator_for(binary)
    if binary == "docker"
      DockerFishGenerator.new(DockerCmdLine.new(@docker_path))
    else
      DockerComposeFishGenerator.new(DockerComposeCmdLine.new(@docker_path))
    end
  end
end

Runner.run ARGV.first if File.expand_path(__FILE__) == File.expand_path($PROGRAM_NAME)
