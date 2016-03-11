#!/usr/bin/env ruby

# Configration
# Use environment variables to pass the configuration. For example:
# docker run --env "FOO=bar"
# Possible options:
# - KEEP_LAST_VERSIONS - the number of releases keep for each repository (default: `2`).
# - DRY_RUN - just print the commands (default: `false`).
# - EXCLUDE_REGEX - regex filter for repository name (default: `alpine|deis|blackhole|none|datadog|cleanup|heroku|python`).

require "open3"
require "csv"
require "yaml"

KEEP_LAST_VERSIONS = ENV.fetch("KEEP_LAST_VERSIONS", "2").to_i
DRY_RUN = YAML.load(ENV.fetch("DRY_RUN", "false"))
EXCLUDE_REGEX = /#{ENV.fetch("EXCLUDE_REGEX", "alpine|deis|blackhole|none|datadog|cleanup|heroku|python")}/

output, status = Open3.capture2e("docker images")
abort output unless status.success?

headers, *rows = CSV.parse(output, col_sep: " ").map { |row| row.first(2) }
headers.map! { |header| header.downcase.to_sym }
images = rows.map { |row| headers.zip(row).to_h }

remove = lambda do |image|
  command = "docker rmi #{image[:repository]}:#{image[:tag]}"
  command.prepend "echo " if DRY_RUN
  output, _status = Open3.capture2e(command)
  puts output
end

puts "deis-cleanup started."

# Deis use two types of image tags - git-<sha> and v<version>. All git-tagged
# images should be removed, in case of version tag we keep KEEP_LAST_VERSIONS
# last images,
filtered = images.reject { |image| image[:repository].match(EXCLUDE_REGEX) }.
  group_by { |image| image[:tag].include?("git") ? :git : :versioned }

%i(git versioned).each do |type|
  filtered[type] ||= {}
end

filtered[:git].each(&remove)
filtered[:versioned].group_by { |image| image[:repository] }.each do |_, repository|
  repository.sort_by { |e| e[:tag].split("v").last.to_i }[0..-(KEEP_LAST_VERSIONS + 1)].each(&remove)
end

puts "deis-cleanup finished."
