require 'json'
require 'rest_client'

module Testor
  module Distribution

    class Client

      class Job

        attr_reader :id
        attr_reader :platform
        attr_reader :adapter
        attr_reader :library

        attr_reader :data
        attr_reader :success

        def initialize(data)
          @id       = data['id']
          @platform = data['platform']['name']
          @adapter  = data['adapter' ]['name']
          @library  = data['library' ]['name']
          @data     = data
          @success  = false
        end

        def run
          @running = true
          if accept
            execute
            report
          end
          @running = false
          @success
        end

        def accept
          puts "ACCEPTING: job.id = #{self.id}"
          response = JSON.parse(RestClient.post("#{service}/jobs/accept", { :id => self.id }))
          response['accepted']
        end

        def execute
          puts "EXECUTING: #{command}"
          system command
          @success = $? == 0
        end

        def report
          puts "REPORTING: success = #{success.inspect}"
          RestClient.post("#{service}/jobs/report", :report => { :job_id => self.id, :green => success })
        end

        def running?
          @running
        end

        def command
          "thor dm:spec -i #{library} -R #{platform} -a #{adapter}"
        end

        def service
          'http://localhost:9292'
        end

      end # class Client

      def start
        while true
          if job = available_jobs.first
            puts "GOT JOB: library = #{job.library}, platform = #{job.platform}, adapter = #{job.adapter}"
            job.run
          else
            sleep(5)
            puts "wake up!"
          end
        end
      end

    private

      def available_jobs
        JSON.parse(RestClient.get('http://localhost:9292/jobs')).map do |data|
          Client::Job.new(data)
        end
      end

    end

  end
end

