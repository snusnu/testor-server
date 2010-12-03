require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-transactions'
require 'dm-types'
require 'dm-serializer/to_json'

module Testor

  def self.next_job(previous_jobs, status)
    Persistence::Job.available(previous_jobs, status).first
  end

  def self.register_commit(library_name)
    Persistence::Job.register_commit(library_name)
  end

  def self.accept_job(id, status)
    job = Persistence::Job.get(id)
    { 'accepted' => job.accept(status) }.to_json
  end

  def self.report_job(report)
    job = Persistence::Job.get(report[:job_id])
    job.create_report(report)
  end

  module Persistence

    class IdentityMap
      def initialize(app)
        @app = app
      end

      def call(env)
        DataMapper.repository { @app.call(env) }
      end
    end

    def self.setup(log_stream, log_level)
      setup_logger(log_stream, log_level) if log_stream

      convention = DataMapper::NamingConventions::Resource::UnderscoredAndPluralizedWithoutModule
      adapter    = DataMapper::setup(:default, Config['database'])
      adapter.resource_naming_convention = convention
      DataMapper.finalize

      adapter
    end

    def self.create(log_stream, log_level)
      setup(log_stream, log_level)
      DataMapper.auto_migrate!
    end

    def self.setup_logger(stream, level)
      DataMapper::Logger.new(log_stream(stream), level)
    end

    def self.log_stream(stream)
      stream == 'stdout' ? $stdout : stream
    end

    class Library

      include DataMapper::Resource

      property :id,   Serial
      property :name, String, :required => true
      property :url,  URI,    :required => true

      has n, :platforms, :through => Resource
      has n, :adapters,  :through => Resource

    end

    class Platform

      include DataMapper::Resource

      property :id,   Serial
      property :name, String, :required => true

      has n, :libraries, :through => Resource
      has n, :adapters,  :through => :libraries

    end

    class Adapter

      include DataMapper::Resource

      property :id,   Serial
      property :name, String, :required => true

      has n, :platforms, :through => Resource
      has n, :libraries, :through => Resource

    end

    class Job

      include DataMapper::Resource

      MODIFIED   = 'modified'
      PROCESSING = 'processing'
      FAIL       = 'fail'
      PASS       = 'pass'
      SKIPPED    = 'skipped'

      property :id,     Serial
      property :status, String, :required => true, :set => [MODIFIED, PROCESSING, FAIL, PASS, SKIPPED]

      belongs_to :platform
      belongs_to :adapter
      belongs_to :library

      has n, :reports

      def self.available(previous_jobs, status)
        matching_status = if status.empty?
          all(:status => MODIFIED) | all(:status => SKIPPED)
        else
          all(:status => status)
        end
        all(:id.not => previous_jobs) & matching_status
      end

      def self.register_commit(gem_name)
        all(:library => Library.first(:name => gem_name)).each { |job| job.update_status(MODIFIED) }
      end

      def create_report(report_attributes)
        transaction do
          report = reports.create(report_attributes)
          update_status(report_attributes['status'])
        end
      end

      def accept(status)
        allowed = status.empty? ? (modified? || skipped?) : true
        allowed ? update(:status => PROCESSING) : false
      end

      def update_status(status)
        return false if modified?
        update(:status => status)
      end

      def modified?
        self.status == MODIFIED
      end

      def skipped?
        self.status == SKIPPED
      end

      def previous_status
        report = reports.last(:order => [:created_at.asc])
        report ? report.status : FAIL
      end

    end

    class Report

      include DataMapper::Resource

      property :id,         Serial
      property :status,     String, :required => true, :set => [Job::PASS, Job::FAIL, Job::SKIPPED]
      property :created_at, DateTime

      belongs_to :job

    end

  end # module Persistence
end # module Testor

