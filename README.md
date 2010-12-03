## Distributed testing server for DataMapper

More to come ...

## Server Installation

    git clone git://github.com/snusnu/testor-server.git
    cd testor-server
    bundle install
    rake config/config.yml.sample
    bundle exec rackup config.ru

## Starting a client

Follow the installation instructions in the
[dm-dev README](http://github.com/datamapper/dm-dev) then run the
following:

    TESTOR_SERVER=http://testor.nextsnu.snusnu.info thor dm:ci:client

