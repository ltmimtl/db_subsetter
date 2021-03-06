$VERBOSE = true
require 'simplecov'
require 'minitest/autorun'
SimpleCov.start do
  add_filter 'test'
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'db_subsetter'

DB_CONFIGS = {
  sqlite: { adapter: 'sqlite3', database: ':memory:' },
  mysql: { adapter: 'mysql2', username: 'root', host: '127.0.0.1', password: '', database: 'db_subsetter' },
  postgres: { adapter: 'postgresql', username: 'postgres', host: '127.0.0.1', password: '', database: 'db_subsetter' }
}.freeze

db = ENV['DATABASE'] || 'sqlite'
DB_CONFIG = DB_CONFIGS[db.to_sym]

$arel_silence_type_casting_deprecation = true

raise ArgumentError, "Invalid database: #{db}.  Must be in [sqlite, mysql, postgres]" if DB_CONFIG.nil?
# ActiveRecord::Base.logger = Logger.new(STDOUT)
