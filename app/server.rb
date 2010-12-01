require 'pathname'

require 'sinatra/base'
require 'models'
require 'views'

require 'mustache/sinatra'

module Testor

  module Distribution

    class Server < Sinatra::Base

      register Mustache::Sinatra

      set :mustache, {
        :namespace => Testor::Distribution::Views
      }

      get '/status' do
        Views::Status.new.render
      end

      get '/jobs/next' do
        job = Testor.next_job(params[:previous_jobs].split(',')) || {}
        job.to_json(
          :only    => [:id],
          :methods => [:library, :platform, :adapter]
        )
      end

      post '/commits' do
        Testor.register_commit(params)
      end

      post '/jobs/accept' do
        Testor.accept_job(params[:id])
      end

      post '/jobs/report' do
        Testor.report_job(params[:report])
      end

    end

  end # module Distribution
end # module Testor

