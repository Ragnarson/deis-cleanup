#!/usr/bin/env ruby

# Configration
# Use environment variables to pass the configuration. For example:
# docker run --env "FOO=bar"
# Possible options:
# - KEEP_LAST_VERSIONS - the number of releases keep for each repository (default: `2`).
# - DRY_RUN - just print the commands (default: `false`).
# - EXCLUDE_REGEX - regex filter for repository name (default: `alpine|deis|blackhole|none|datadog|cleanup|heroku|python).

require "open3"
require "csv"
require "yaml"

def execute(command, abort_on_failure = false)
  output, status = Open3.capture2e(command)
  abort output if abort_on_failure && !status.success?
  output
end

KEEP_LAST_VERSIONS = ENV.fetch("KEEP_LAST_VERSIONS", "2").to_i
DRY_RUN = YAML.load(ENV.fetch("DRY_RUN", "false"))
EXCLUDE_REGEX = /#{ENV.fetch("EXCLUDE_REGEX", "alpine|deis|blackhole|none|datadog|cleanup|heroku|python")}/
CLEANUP_CONTAINERS = YAML.load(ENV.fetch("CLEANUP_CONTAINERS", "true"))

remove_image = lambda do |image|
  command = "docker rmi #{image[:repository]}:#{image[:tag]}"
  command.prepend "echo " if DRY_RUN
  puts execute(command)
end

remove_container = lambda do |container|
  command = "docker rm #{container[:id]}"
  command.prepend "echo #{container[:name]}: " if DRY_RUN
  puts execute(command)
end

output = execute("docker images", true)
headers, *rows = CSV.parse(output, col_sep: " ").map { |row| row.first(2) }
headers.map! { |header| header.downcase.to_sym }
images = rows.map { |row| headers.zip(row).to_h }

puts "deis-cleanup started."

if CLEANUP_CONTAINERS
  puts "removing containers"

  output = execute("docker ps -a --format '{{.ID}};{{.Names}}' --filter 'exited=0'", true)
  rows = CSV.parse(output, col_sep: ";")
  rows.map { |row| %i(id name).zip(row).to_h }.reject { |container| container[:name].match(EXCLUDE_REGEX) }.
    each(&remove_container)
end

# Deis use two types of image tags - git-<sha> and v<version>. All git-tagged
# images should be removed, in case of version tag we keep KEEP_LAST_VERSIONS
# last images,
puts "removing images"
filtered = images.reject { |image| image[:repository].match(EXCLUDE_REGEX) }.
  group_by { |image| image[:tag].include?("git") ? :git : :versioned }

%i(git versioned).each do |type|
  filtered[type] ||= {}
end

filtered[:git].each(&remove_image)
filtered[:versioned].group_by { |image| image[:repository] }.each do |_, repository|
  repository.sort_by { |e| e[:tag].split("v").last.to_i }[0..-(KEEP_LAST_VERSIONS + 1)].each(&remove_image)
end

puts "deis-cleanup finished."
