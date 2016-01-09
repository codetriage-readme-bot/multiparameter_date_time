# MultiparameterDateTime

Set a DateTime via two accessors, one for the date, one for the time

[![Build Status](https://secure.travis-ci.org/Casecommons/multiparameter_date_time.png?branch=master)](https://travis-ci.org/Casecommons/multiparameter_date_time)
[![Code Climate](https://codeclimate.com/github/Casecommons/multiparameter_date_time.png)](https://codeclimate.com/github/Casecommons/multiparameter_date_time)
[![Gem Version](https://badge.fury.io/rb/multiparameter_date_time.png)](https://rubygems.org/gems/multiparameter_date_time)
[![Dependency Status](https://gemnasium.com/Casecommons/multiparameter_date_time.png)](https://gemnasium.com/Casecommons/multiparameter_date_time)

## Installation

Add this line to your application's Gemfile:

    gem 'multiparameter_date_time'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install multiparameter_date_time

Note that Ruby 1.9.2+ is required.

## Usage

```ruby
class Article < ActiveRecord::Base
  include MultiparameterDateTime

  multiparameter_date_time :publish_at
end

record = Article.new(
  :publish_at_date_part => '01/01/2001',
  :publish_at_time_part => '4:30 pm'
)

record.publish_at #=> Mon, 01 Jan 2001 16:30:00 +0000

record.publish_at_date_part = '2/3/2004'
record.publish_at #=> Tue, 03 Feb 2004 16:30:00 +0000

record = Article.new(
  :publish_at_date_part => '01/01/2001',
)

record.publish_at #=> :incomplete
record.publish_at_date_part #=> '01/01/2001'
record.publish_at_time_part #=> nil

record = Article.new(
  :publish_at_time_part => '09:30 am',
)

record.publish_at #=> :incomplete
record.publish_at_date_part #=> nil
record.publish_at_time_part #=> '09:30 am'
```

### Configuring the date and time formats
In config/initializers/multiparameter\_date\_time.rb:

```ruby
MultiparameterDateTime.date_format = '%-m/%-d/%0Y'
MultiparameterDateTime.time_format = '%-I:%0M %P'
```

### Validating the multipart date time data

```ruby
validates :published_at, presence: true, is_valid_multiparameter_date_time: true
```

### Accessing the datetime error message used

```ruby
IsValidMultiparameterDateTimeValidator.invalid_format_error_message
```

### Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### Customizing the error message via I18n

This gem supports custom error messages using the I18n gem. There is one message key
for a missing date part and another for a missing time part. Default messages are
provided if you choose not to supply your own.

```yaml
en:
  activerecord:
    errors:
      models:
        <your_model>:
          attributes:
            ended_at_time_part:
              blank: '<your message>'
            ended_at_date_part:
              blank: '<your message>'
```

## License

Copyright © 2012–2016 Case Commons, LLC. License is available in the LICENSE file.
