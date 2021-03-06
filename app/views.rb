require 'mustache'

module Testor
  module Distribution
    module Views

      module Helpers

        def users
          Persistence::User.all.map do |user|
            user.attributes.merge(
              :since => formatted_date(user.created_at),
              :count => '???',
              :hours => '???'
            )
          end
        end

        def formatted_date(date, time = true, year = true)
          f_date = date.strftime("%d.%m.#{year ? '%Y' : ''}")
          f_date += " - <span class='time'>#{date.strftime('%H:%M')}</span>" if time
          f_date
        end

        def formatted_time(time)
          hours   = (time / 3600).to_i
          minutes = (time / 60 - hours * 60).to_i
          seconds = (time - (minutes * 60 + hours * 3600))

          "%02d:%02d:%02d" % [hours, minutes, seconds]
        end

        def commit_href(report)
          "http://github.com/datamapper/#{report.library_name}/commit/#{report.revision}"
        end

      end

      class Home < Mustache

        include Views::Helpers

        self.template_file = Pathname(__FILE__).dirname.join('templates/home.html')

      end

      class Status < Mustache

        self.template_file = Pathname(__FILE__).dirname.join('templates/status.html')

        def libraries
          matrix = []

          Persistence::Library.all.each do |library|

            result             = {}
            result[:name]      = library.name
            result[:adapters]  = library.adapters
            result[:platforms] = library.platforms.map do |platform|
              {
                :name     => platform.name,
                :adapters => library.adapters.map { |adapter|
                  job = Persistence::Job.first(
                    :library  => library,
                    :platform => platform,
                    :adapter  => adapter
                  )
                  {
                    :name            => adapter.name,
                    :status          => job.status,
                    :previous_status => job.previous_status,
                    :history_link    => history_link(job)
                  }
                }

              }
            end

            matrix << result

          end

          matrix
        end

        def history_link(job)
          "<a href='/jobs/#{job.id}/reports'>#{job.status}</a>"
        end

      end

      class Reports < Mustache

        include Views::Helpers

        self.template_file = Pathname(__FILE__).dirname.join('templates/reports.html')

        attr_reader :reports

        def initialize(job_id)
          @reports = Persistence::Report.all(:job_id  => job_id, :order => [:created_at.desc])
        end

        def reports
          @reports.map do |report|
            report.attributes.merge(
              :date          => formatted_date(report.created_at),
              :output_path   => "/reports/#{report.id}/output",
              :library_name  => report.library_name,
              :platform_name => report.platform_name,
              :adapter_name  => report.adapter_name,
              :commit_href   => commit_href(report),
              :duration      => formatted_time(report.duration)
            )
          end
        end

        class Output < Mustache

          include Views::Helpers

          self.template_file = Pathname(__FILE__).dirname.join('templates/output.html')

          def initialize(report_id)
            @report = Persistence::Report.get(report_id)
          end

          def output
            @report.output
          end

          def report
            @report.attributes.merge(
              :date          => formatted_date(@report.created_at),
              :library_name  => @report.library_name,
              :platform_name => @report.platform_name,
              :adapter_name  => @report.adapter_name,
              :commit_href   => commit_href(@report),
              :duration      => formatted_time(@report.duration)
            )
          end

        end

      end

      class Users < Mustache

        include Views::Helpers

        self.template_file = Pathname(__FILE__).dirname.join('templates/users/index.html')

        class Edit < Mustache

          include Views::Helpers

          self.template_file = Pathname(__FILE__).dirname.join('templates/users/edit.html')

          attr_reader :user

          def initialize(user)
            @user = user
          end

        end

      end

    end
  end
end

