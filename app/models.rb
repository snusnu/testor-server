require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-transactions'
require 'dm-types'
require 'dm-serializer/to_json'
require 'dm-zone-types'

module Testor

  def self.next_job(previous_jobs, status)
    Persistence::Job.available(previous_jobs, status).first
  end

  def self.register_commit(library_name, revision)
    Persistence::Job.register_commit(library_name, revision)
  end

  def self.accept_job(id, status)
    job = Persistence::Job.get(id)
    job.accept(status)
  end

  def self.report_job(user, report)
    job = Persistence::Job.get(report[:job_id])
    job.create_report(user, report)
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

    class User

      include DataMapper::Resource

      property :login,      String, :key => true
      property :token,      String, :default => lambda { |_, _|
        while token = Digest::SHA1.hexdigest(rand(36**8).to_s(36))[4..20]
          return token if first(:token => token).nil?
        end
      }

      property :created_at, ZonedTime

      has n, :reports

    end

    class Library

      include DataMapper::Resource

      property :id,       Serial
      property :name,     String, :required => true
      property :url,      URI,    :required => true
      property :revision, String, :required => true

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

      def self.register_commit(library_name, revision)
        transaction do
          library = Library.first(:name => library_name)
          library.update(:revision => revision)
          all(:library => library).each do |job|
            job.update_status(MODIFIED)
          end
        end
      end

      def create_report(user, report_attributes)
        transaction do
          unless skip_report?(report_attributes)
            report = reports.create(report_attributes.merge(:user => user))
          end
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

      def skip_report?(attributes)
        attributes['status'] == SKIPPED && previous_status == SKIPPED
      end

      def previous_status
        report = reports.last(:order => [:created_at.asc])
        report ? report.status : FAIL
      end

      def library_name
        library.name
      end

      def revision
        library.revision
      end

      def platform_name
        platform.name
      end

      def adapter_name
        adapter.name
      end

    end

    class Report

      include DataMapper::Resource

      property :id,         Serial
      property :status,     String,  :required => true, :set => [Job::PASS, Job::FAIL, Job::SKIPPED]
      property :revision,   String,  :required => true
      property :output,     Text,    :required => true, :length => 2**24
      property :duration,   Integer, :required => true
      property :created_at, ZonedTime

      belongs_to :user
      belongs_to :job

      def library_name
        job.library_name
      end

      def platform_name
        job.platform_name
      end

      def adapter_name
        job.adapter_name
      end

    end

  end # module Persistence
end # module Testor

