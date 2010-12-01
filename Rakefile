$LOAD_PATH.unshift(File.expand_path('../app', __FILE__))

log_stream = ENV['DM_LOG']
log_level  = ENV['DM_LOG_LEVEL'] || :debug

desc "Generate a sample config.yml"
file "config/config.yml" => "config/config.yml.sample" do |t|
  sh "cp #{t.prerequisites.first} #{t.name}"
end

namespace :db do

  desc "Import the initially available jobs"
  task :seed do

    require 'config'
    require 'models'

    Testor::Persistence.create(log_stream, log_level)

    Testor::Persistence::Platform.create :name => '1.8.7'
    Testor::Persistence::Platform.create :name => '1.9.2'
    Testor::Persistence::Platform.create :name => 'jruby'
    Testor::Persistence::Platform.create :name => 'rbx'

    Testor::Persistence::Adapter.create :name => 'in_memory', :platforms => Testor::Persistence::Platform.all
    Testor::Persistence::Adapter.create :name => 'yaml',      :platforms => Testor::Persistence::Platform.all
    Testor::Persistence::Adapter.create :name => 'sqlite',    :platforms => Testor::Persistence::Platform.all
    Testor::Persistence::Adapter.create :name => 'postgres',  :platforms => Testor::Persistence::Platform.all
    Testor::Persistence::Adapter.create :name => 'mysql',     :platforms => Testor::Persistence::Platform.all
    Testor::Persistence::Adapter.create :name => 'oracle',    :platforms => Testor::Persistence::Platform.all
    Testor::Persistence::Adapter.create :name => 'sqlserver', :platforms => Testor::Persistence::Platform.all

    special_gems = %w[
      dm-active_model
      dm-sqlite-adapter
      dm-postgres-adapter
      dm-mysql-adapter
      dm-oracle-adapter
      dm-sqlserver-adapter
    ]

    Testor::Persistence::Library.create(
      :name      => 'dm-active_model',
      :url       => 'http://github.com/datamapper/dm-active_model',
      :adapters  => [Testor::Persistence::Adapter.first(:name => 'in_memory')],
      :platforms => Testor::Persistence::Platform.all
    )

    %w[yaml sqlite postgres mysql oracle sqlserver].each do |adapter|
      Testor::Persistence::Library.create(
        :name      => "dm-#{adapter}-adapter",
        :url       => "http://github.com/datamapper/dm-#{adapter}-adapter",
        :adapters  => [Testor::Persistence::Adapter.first(:name => adapter)],
        :platforms => Testor::Persistence::Platform.all
      )
    end

    Testor::Config['repositories'].each do |repository|
      next if special_gems.include?(repository['name'])
      Testor::Persistence::Library.create(
        :name      => repository['name'],
        :url       => repository['url'],
        :adapters  => Testor::Persistence::Adapter.all,
        :platforms => Testor::Persistence::Platform.all
      )
    end

    Testor::Persistence::Library.all.each do |library|
      library.platforms.each do |platform|
        library.adapters.each do |adapter|
          Testor::Persistence::Job.create(
            :status   => Testor::Persistence::Job::MODIFIED,
            :platform => platform,
            :adapter  => adapter,
            :library  => library
          )
        end
      end
    end

  end
end

