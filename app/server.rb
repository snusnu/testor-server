require 'pathname'

require 'json'
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
        previous_jobs = params[:previous_jobs].split(',')
        status        = params[:status].split(',')
        job = Testor.next_job(previous_jobs, status) || {}
        job.to_json(
          :only    => [:id],
          :methods => [
            :library_name,
            :platform_name,
            :adapter_name,
            :revision,
            :previous_status
          ]
        )
      end

      get '/jobs/:id/reports' do
        Views::Reports.new(params[:id]).render
      end

      get '/reports/:id/output' do
        Views::Reports::Output.new(params[:id]).render
      end

      post '/commits' do
        push     = JSON.parse(params[:payload])
        library  = push['repository']['name']
        revision = push['commits'].first['id']
        Testor.register_commit(library, revision)
      end

      post '/jobs/accept' do
        Testor.accept_job(params[:id], (params[:status] || '').split(','))
      end

      post '/jobs/report' do
        Testor.report_job(params[:report])
      end

    end

  end # module Distribution
end # module Testor

