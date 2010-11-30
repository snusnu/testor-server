require 'pathname'
require 'yaml'

module Testor

  def self.root
    @root ||= Pathname(File.dirname(__FILE__))
  end

  module Config

    def self.root
      @root ||= Testor.root.join('../config')
    end

    def self.[](key)
      config[key]
    end

  private

    def self.config
      return @config if @config

      @config = YAML.load_file(root.join('config.yml'))
    end

  end

end

