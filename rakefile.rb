# frozen_string_literal: true

require 'rake/clean'
require './rake_extensions.rb'

EXE_NAME = 'hello'

desc 'build release'
task :build do
  sh 'cargo build --release'
  pack_release
end

desc 'create new version and release'
task :create_release do
  current_tag = `git describe --tags`
  versioner = Versioner.for(:cargo_toml, '.')
  current_version = versioner.get_current_version
  unless current_tag.start_with?(current_version)
    raise "current tag #{current_tag} does not match current version: #{current_version}"
  end
  do_create_release(versioner)
end

def do_create_release(versioner)
  require 'highline'
  cli = HighLine.new
  cli.choose do |menu|
    default = :minor
    menu.prompt = "this will create and tag a new version (default: #{default}) "
    menu.choice(:minor) do
      create_and_tag_new_version(versioner, :minor)
    end
    menu.choice(:major) do
      create_and_tag_new_version(versioner, :major)
    end
    menu.choice(:patch) do
      create_and_tag_new_version(versioner, :patch)
    end
    menu.choice(:abort) { cli.say('ok...maybe later') }
    menu.default = default
  end
end

def create_and_tag_new_version(versioner, jump)
  current_version = versioner.get_current_version
  next_version = versioner.get_next_version(jump)
  assert_tag_exists(current_version)
  create_changelog(current_version, next_version)
  versioner.increment_version(jump)
  sh 'git add .'
  sh "git commit -m \"[](chore): version bump from #{current_version} => #{next_version}\""
  sh "git tag #{next_version}"
  puts 'to undo the last commit and the tag, execute:'
  puts "git reset --hard HEAD~1 && git tag -d #{next_version}"
end


def pack_release
  require 'zip'
  exe_file = if OS.windows?
               "#{EXE_NAME}.exe"
             else
               EXE_NAME
             end
  exe_path = "target/release/#{exe_file}"

  zipfile_name = "#{EXE_NAME}.zip"

  Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
    zipfile.add(exe_file, exe_path)
  end
end
