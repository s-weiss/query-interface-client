# Query Interface Client

``query-interface-client`` provides a flexible query interface for Her::Model.

## Installation

```
$ gem install query-interface-client
```

```ruby
require 'query-interface-client'
```

or use ``gem 'query-interface-client'`` in your Gemfile when using bundler.

##Examples

### Adding QueryInterface to a Model

```ruby

class SomeClass

  include Her::Model
  include Her::Model::ResourceExtension
  include QueryInterface::Client::Resource

  #...

end
```

### Usage

```ruby
SomeClass.query
  .filter(status: 'ok', foo: 'bar')
  .count

most_urgent = SomeClass.query
  .filter(urgent:true)
  .order('-urgency')
  .first

SomeClass.query.paginate(page: 3, per_page: 13)
```
