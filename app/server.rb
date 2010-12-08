require 'pathname'

require 'json'
require 'sinatra/base'
require 'mustache/sinatra'
require 'omniauth'

require 'config'
require 'models'
require 'views'

module Testor

  module Distribution

    class Server < Sinatra::Base

      enable :sessions

      register Mustache::Sinatra

      set :mustache, {
        :namespace => Testor::Distribution::Views
      }

      use OmniAuth::Builder do
        provider :github, Testor::Config['github']['id'], Testor::Config['github']['secret']
      end

      helpers do

        def authenticate_params(user)
          authenticate(user[:login], user[:token])
        end

        def authenticate_session(login)
          authenticate(login, session[:token])
        end

        def authenticate(login, token)
          user = Persistence::User.first(:login => login)
          halt 403 unless user && authorized?(user, token)
          user
        end

        def authorized?(user, token)
          user.token == token
        end

      end

      get '/' do
        Views::Home.new.render
      end

      get '/auth/github/callback' do
        login = request.env['omniauth.auth']['user_info']['nickname']
        user = Persistence::User.first_or_create(:login => login)

        session[:token] = user.token

        redirect "/users/#{user.login}/edit"
      end

      get '/users/:login/edit' do
        user = authenticate_session(params[:login])
        Views::Users::Edit.new(user).render
      end

      get '/users/:login' do
        Views::Users::Show.new(params[:login]).render
      end

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
        authenticate_params(params[:user])
        Testor.accept_job(params[:id], (params[:status] || '').split(','))
      end

      post '/jobs/report' do
        authenticate_params(params[:user])
        Testor.report_job(params[:report])
      end

    end

  end # module Distribution
end # module Testor

