# Bind Log Analyzer

Simple analysis and SQL storage for Bind DNS server's logs.
The gem includes a web interface to analyze the data collected from the analyzed logs.

![Bind Log Analyzer web interface](http://f.cl.ly/items/0A1A173R3b012R1V2x2b/bind_log_analyzer_screenshot_1.jpg)

## Requirements

This gem was tested with:

- ruby-1.9.3-p125
- rubygem (1.8.15)
- bundler (1.0.21)
- activerecord (3.2.2)

## Installation

Just install the gem:

    gem install bind_log_analyzer

The gem requires **active_record** but you probably need to install the right adapter. As example, if you'll use MySQL, install the **mysql2** gem.

## Configuration

### Bind

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

### Database

To store the logs you can use every database supported by ActiveRecord. Just create a database and a user with the right privileges. You can provide the -s flag to *BindLogAnalyzer* to make it create the table. Otherwise create it by yourself.
This is the MySQL CREATE TABLE syntax:

    CREATE TABLE `logs` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `date` datetime NOT NULL,
      `client` varchar(255) NOT NULL,
      `query` varchar(255) NOT NULL,
      `q_type` varchar(255) NOT NULL,
      `server` varchar(255) NOT NULL,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;

## Usage

Use the provided --help to get various options available. This is the default help:

    -h, --help                       Display this screen
    -v, --verbose LEVEL              Enables verbose output. Use level 1 for WARN, 2 for INFO and 3 for DEBUG
    -w, --webserver [HTTP_PORT]      Launches the Sinatra web server on specified port, or 4567 if omitted
    -s, --setup                      Creates the needed tables in the database.
    -f, --file FILE                  Indicates the log file to parse. It's mandatory if you don't specify the --webserver option.
    -c, --config CONFIG              A yaml file containing the database configurations under the "database" entry
    -a, --adapter ADAPTER            The database name to save the logs
    -d, --database DATABASE          The database name to save the logs
    -H, --host HOST                  The address (IP, hostname or path) of the database
    -P, --port PORT                  The port of the database
    -u, --user USER                  The username to be used to connect to the database
    -p, --password PASSWORD          The password of the user

The first time you launch *BindLogAnalyzer* you can use the **-s|--setup** flag to make it create the table (using ActiveRecord::Migration).
The database credentials can be provided using the needed flags or creating a YAML file containing all the informations under the **database** key. This is an example:

    database:
      adapter: mysql2
      database: bindloganalyzer
      host: localhost
      port: 3306
      username: root
      password:  

There are two usage of the gem:

* Use **--file FILE** flag to pass to *BindLogAnalyzer* the file to analyze.
* Use **-w, --webserver [HTTP_PORT]** to start the Sinatra webserver and watch the stats on the collected data.

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

The script **/usr/local/bin/update_bind_log_analyzer.sh** can be wherever you prefer. Its typical content if you use RVM and a dedicated gemset for *BindLogAnalyzer*, can be:

    #!/bin/bash

    # *************************** #
    #       EDIT THESE VARS       #
    # *************************** #
    BLA_RVM_GEMSET="1.9.3-p125@bind_log_analyzer"
    BLA_USER="my_username"
    BLA_DB_FILE="/etc/bind_log_analyzer/database.yml"

    # *************************** #
    # DO NOT EDIT BELOW THIS LINE #
    # *************************** #
    . /home/$BLA_USER/.rvm/scripts/rvm && source "/home/$BLA_USER/.rvm/scripts/rvm"
    rvm use $BLA_RVM_GEMSET
    bind_log_analyzer --config $BLA_DB_FILE --file $1

## Performance

On a 1.6 Ghz Intel Core i5 with SSD SATA2 disk, using Ruby-1.9.3-p125 and MySQL 5.5.15, this is the performance:

    ~$ time bind_log_analyzer -f query.log -c database.yml   
    Analyzed 319758 lines and correctly stored 319758 logs
    bind_log_analyzer -f query.log -c database.yml  322,44s user 22,90s system 76% cpu 7:33,17 total
    
which is equivalent to ±706 query/sec.

## Changelog

### 0.2.1

If the **-c, --config CONFIG** parameter is not specified, it tries to use a *database.yml* file in the directory from where the gem was launched

### 0.2.0

First version including the web interface

### 0.1.0

First stable version