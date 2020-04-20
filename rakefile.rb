# frozen_string_literal: true

require 'rake/clean'
require './rake_extensions.rb'

EXE_NAME = 'hello'

desc 'build release'
task :build do
  sh 'cargo build --release'
  pack_release
end

def pack_release
  require 'zip'
  exe_file = if OS.windows?
               "#{EXE_NAME}.zip"
             else
               EXE_NAME
             end
  exe_path = "target/release/#{exe_file}"

  zipfile_name = "#{EXE_NAME}.zip"

  Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
    zipfile.add(exe_file, exe_path)
  end
end
