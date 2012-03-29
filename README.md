# Bind Log Analyzer

Simple analysis and SQL storage for Bind DNS server's logs

## Requirements

This program was tested with:

- ruby-1.9.3-p125
- rubygem (1.8.15)
- bundler (1.0.21)
- activerecord (3.2.2)

## Installation

Clone the repository then enter the folder and launch _bundle install_ to install required gems

## Configuration

Edit _config/databases.yml_ with your database credentials.
Then launch _rake db:migrate_ to create the database.

To configure **Bind** add these lines to _/etc/bind/named.conf.options_ (or whatever your s.o. and bind installation require)

    logging{
        channel "querylog" {
                file "/var/log/bind/query.log";
                print-time yes;
        };

        category queries { querylog; };
    };

Restart bind and make sure than the _query.log_ file contains lines as this:

    28-Mar-2012 16:48:19.694 client 192.168.10.38#58767: query: www.github.com IN A + (192.168.10.1)

or the regexp will fail :(

## Usage

Use _bundle exex bin/bind_log_analyzer_ to launch the program. It will analyze the _query.log_ file in the program folder.

## Automatization

A good way to use this script is to let it be launched by **logrotate** so create the _/etc/logrotate.d/bind_ file with this content:

    /var/log/named/query.log {
        weekly
        missingok
        rotate 8
        compress
        delaycompress
        notifempty
        create 644 bind bind
        postrotate
            if [ -e /var/log/named/query.log.1 ]; then
                exec su - YOUR_USER -c '/usr/local/bin/update_bind_log_analyzer.sh /var/log/named/query.log.1'
            fi
        endscript
    } 

The script **/usr/local/bin/update_bind_log_analyzer.sh** can be wherever you prefer. A template is provided with the software (you need to set some vars to let it work, watch at the top the file).

## To do

- Add _optparse_ gem to parse command-line arguments (and add them too :)
- Transform this program into a gem
- Add a web interface to query the results (with awesome graphs, obviously :)
