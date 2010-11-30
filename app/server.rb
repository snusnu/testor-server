require 'sinatra/base'
require 'models'

module Testor

  module Distribution

    class Server < Sinatra::Base

      get '/jobs' do
        Testor.list_jobs.to_json(:only => [:id], :methods => [:library, :platform, :adapter])
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

