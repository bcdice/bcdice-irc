# frozen_string_literal: true

require 'pathname'

require 'rake/testtask'
require 'yard'

BCDICE_IRC_PROTO_DIR = 'vendor/bcdice-irc-proto'
BCDICE_IRC_PROTO = "#{BCDICE_IRC_PROTO_DIR}/bcdice_irc.proto"

GRPC_OUT_DIR = 'lib/bcdice_irc_proto'
BCDICE_IRC_PROTO_PB_RB = "#{GRPC_OUT_DIR}/bcdice_irc_proto_pb.rb"

desc 'RPC用のライブラリを生成する'
task proto: BCDICE_IRC_PROTO_PB_RB

directory GRPC_OUT_DIR

file BCDICE_IRC_PROTO_PB_RB => [GRPC_OUT_DIR, BCDICE_IRC_PROTO] do
  args = [
    "-I #{BCDICE_IRC_PROTO_DIR}",
    "--ruby_out=#{GRPC_OUT_DIR}",
    "--grpc_out=#{GRPC_OUT_DIR}",
    BCDICE_IRC_PROTO,
  ]
  sh "bundle exec grpc_tools_ruby_protoc #{args.join(' ')}"
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.libs << 'vendor/bcdice/src'

  t.test_files = FileList['test/**/*_test.rb']
end

YARD::Rake::YardocTask.new do |t|
  t.files = [
    'lib/**/*.rb',
    'exe/**/*.rb',
    '-',
    'README.md',
    'master_commands.md',
  ]
  t.options = [
    '--protected',
    '--private',
    '--markup-provider=redcarpet',
    '--markup=markdown',
  ]
end

desc 'タグ t のアーカイブを作成する'
task :archive, [:t] do |_t, args|
  tag = args[:t]
  raise ArgumentError, 'タグを指定してください' unless tag

  m = tag.match(/\Av(\d+\.\d+\.\d+.*)/)
  raise ArgumentError, "無効なタグの書式です: #{tag}" unless m

  ver = m[1]
  prefix = "bcdice-irc-#{ver}"
  tmp_dir = "archive-#{ver}"

  # @type [Pathname]
  tmp_dir_prefix_path = Pathname.new(tmp_dir) / prefix
  tmp_dir_prefix_path.mkpath

  # BCDice IRCのファイルをコピーする
  sh "git archive --format=tar #{tag} | (cd #{tmp_dir_prefix_path} && tar -xf -)"

  sh "git checkout #{tag}"
  sh 'git submodule update'

  cd('vendor/bcdice') do
    # BCDiceのファイルをコピーする
    sh "git archive --format=tar --prefix=vendor/bcdice/ HEAD | (cd ../../#{tmp_dir_prefix_path} && tar -xf -)"
  end

  cd(tmp_dir) do
    prefix_with_bcdice = "#{prefix}-with-bcdice"

    # アーカイブを作成する
    sh "tar -zcf #{prefix_with_bcdice}.tar.gz #{prefix}"
    sh "zip -r #{prefix_with_bcdice}.zip #{prefix}"

    rm_r prefix
  end
end

task default: :test
