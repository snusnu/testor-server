## Distributed testing server for DataMapper

More to come ...

## Server Installation

    git clone git://github.com/snusnu/testor-server.git
    cd testor-server
    bundle install
    rake config/config.yml.sample
    bundle exec rackup config.ru

## Starting a client

    cd testor-server
    irb -r client.rb
    >> Testor::Distribution::Client.new.start

