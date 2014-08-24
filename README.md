# RemoteResource

RemoteResource is a gem to use resources with REST services.

## Goal of RemoteResource

To replace `ActiveResource` by providing a dynamic and customizable API interface for REST services.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'remote_resource', git: 'git@lab.digidentity.eu:jvanderpas/remote_resource.git'
```


## Usage

Simply include the `RemoteResource::Base` module in the class you want to enable for the REST services.

```ruby
class ContactPerson
  include RemoteResource::Base

  self.site    = "https://www.myapp.com"
  self.version = '/v2'
end
```

### Options

You can set a few options for the `RemoteResource` enabled class.


#### Base URL options (`base_url`)

The `base_url` is constructed from the `.site`, `.version`,  `.path_prefix`, `.path_postfix`, `.collection`, and `.collection_name` options. The `.collection_name` is automatically constructed from the relative class name.

We will use the `ContactPerson` class for these examples, with the `.collection_name` of `'contact_person'`:

* `.site`: This sets the URL which should be used to construct the `base_url`.
    * *Example:* `.site = "https://www.myapp.com"`
    * *`base_url`:* `https://www.myapp.com/contact_person`
* `.version`: This sets the API version for the path, after the `.site` and before the `.path_prefix` that is used to construct the `base_url`.
    * *Example:* `.version = "/api/v2"`
    * *`base_url`:* `https://www.myapp.com/api/v2/contact_person`
* `.path_prefix`: This sets the prefix for the path, after the `.version` and before the `.collection_name` that is used to construct the `base_url`.
    * *Example:* `.path_prefix = "/registration"`
    * *`base_url`:* `https://www.myapp.com/registration/contact_person`
* `.path_postfix`: This sets the postfix for the path, after the `.collection_name` that is used to construct the `base_url`.
    * *Example:* `.path_postfix = "/new"`
    * *`base_url`:* `https://www.myapp.com/contact_person/new`
* `.collection`: This toggles the pluralization of the `collection_name` that is used to construct the `base_url`.
    * *Default:* `false`
    * *Example:* `.collection = true`
    * *`base_url`:* `https://www.myapp.com/contact_persons`
* `.collection_name`: This sets the `collection_name` that is used to construct the `base_url`.
    * *Example:* `.collection_name = "company"`
    * *`base_url`:* `https://www.myapp.com/company`

**override**

To override the `base_url` completely, you can use the `base_url` option. This option should be passed into the `connection_options` hash when making a request:

* `base_url`: This sets the `base_url`. *note: this does not override the `.content_type` option*
    * *Example:* `{ base_url: "https://api.foo.com/v1" }`
    * *`base_url`:* `https://api.foo.com/v1`


#### Request options

Apart from the options which manipulate the `base_url`, there are some more:

* `.extra_headers`: This sets the extra headers which are merged with the `.default_headers` and should be used for the request. *note: you can't set the `.default_headers`*
    * *Default:* `.default_headers`: `{ "Content-Type" => "application/json" }`
    * *Example:* `.extra_headers = { "X-Locale" => "en" }`
    * `.headers`: `{ "Content-Type" => "application/json", "X-Locale" => "en" }`
* `.content_type`: This sets the content-type which should be used for the request URL. *note: this is appended to the `base_url`*
    * *Default:* `".json"`
    * *`base_url`:* `https://www.myapp.com/contact_person`
    * *Example:* `.content-type = ".json"`
    * *Request URL:* `https://www.myapp.com/contact_person.json`

#### Body and params options

Last but not least, you can pack the request body or params in a `root_element`:

* `.root_element`: This sets the `root_element` in which the request body or params should be 'packed' for the request.
    * *Params:* `{ email_address: "foo@bar.com", phone_number: "0031701234567" }`
    * *Example:* `.root_element = :contact_person`
    * *Packed params:* `{ "contact_person" => { email_address: "foo@bar.com", phone_number: "0031701234567" } }`


### Querying

#### Finder methods

You can use the `.find`, `.find_by` and `.all` class methods:

```ruby
# use the `id` as argument
ContactPerson.find(12)

# use a conditions `Hash` as argument
ContactPerson.find_by(username: 'foobar')
```

To override the given `options`, you can pass in a `connection_options` hash:

```ruby
connection_options: { root_element: :contact_person, headers: { "X-Locale" => "nl" } }

# use the `id` as argument
ContactPerson.find(12, connection_options)

# use a conditions `Hash` as argument
ContactPerson.find_by((username: 'foobar'), connection_options)

# just the whole collection
ContactPerson.all
```

#### Persistence methods

You can use the `.create` class method and the `#save` instance method:


```ruby
# .create
ContactPerson.create(username: 'aapmies', first_name: 'Mies')

# #save
contact_person = ContactPerson.new(id: 12)
contact_person.username = 'aapmies'
contact_person.save
```
To override the given `options`, you can pass in a `connection_options` hash:

```ruby
connection_options: { root_element: :contact_person, headers: { "X-Locale" => "nl" } }

contact_person = ContactPerson.new(id: 12)
contact_person.username = 'aapmies'
contact_person.save(connection_options)
```

#### REST methods

You can use the `.get`, `.put`, `.patch` and `.post` class methods  and the `
#get`, `#put`, `#patch` and `#post` instance methods.


#### With a `connection_options` block

You can make your requests in a `connection_options` block. All the requests in the block will use the passed in `connection_options`.

```ruby
ContactPerson.with_connection_options(headers: { "X-Locale" => "en" }) do
  ContactPerson.find_by(username: 'foobar')
  ContactPerson.find_by(username: 'aapmies', (content-type: '.xml'))
  ContactPerson.find_by((username: 'viking'), (headers: { "X-Locale" => "nl" }))
end
```

This will result in two request which use the `{ headers: { "X-Locale" => "en" } }` as `connection_options`, one which will use the `{ headers: { "X-Locale" => "nl" } }` as `connection_options`. And one that will append `.xml` to the request URL.

### Responses

The response body of the request will be 'unpacked' from the `root_element` if necessary and parsed. The resulting `Hash` will be used to assign the attributes of the resource.

However if you want to access the response of the request, you can use the `#_response` method. This returns a `RemoteResource::Response` object with the `#response_body` and `#response_code` methods.


```ruby
contact_person = ContactPerson.find_by((username: 'foobar'), connection_options)
contact_person._response                 #=> RemoteResource::Response
contact_person._response.response_code   #=> 200
contact_person._response.response_body   #=> '{"username":"foobar", "name":"Foo", "surname":"Bar"}'
```


