# Gain

Accounting application for stock investments. Track positions, lots, gains and losses, and generate reports for tax filings.

FIFO accounting.

## Requirements

Ruby and Ruby on Rails are the primary requirements.

## Installation

To get started, add a database configuration file in `config/database.yml`. The file `database_sample.yml` provides an example file. Create the database with `bin/rails db:create` and run the migrations with `bin/rails db:migrate`. SQLite is the default database.

Multiple users can sign up at `/sign_up`, but to disable the ability for sign ups, modify the Clearance settings in `clearance.rb`.

## Features

* Short and long term (> 364 days) gain tracking;
* IRS Schedule D report;
* Buy, sell, split and conversion tracking;
