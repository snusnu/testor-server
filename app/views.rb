require 'mustache'

module Testor
  module Distribution
    module Views

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
                :adapters => platform.adapters.map { |adapter|
                  {
                    :name   => adapter.name,
                    :status => Persistence::Job.first(
                      :library  => library,
                      :platform => platform,
                      :adapter  => adapter
                    ).status
                  }
                }

              }
            end

            matrix << result

          end

          matrix
        end

      end

    end
  end
end

