[![Build Status](https://app.travis-ci.com/digidentity/ddy_remote_resource.svg?token=mVPURD2PVoqUVtqpx3sA&branch=main)](https://app.travis-ci.com/digidentity/ddy_remote_resource)

# RemoteResource

RemoteResource is a gem to consume resources with REST services.

## Goal of RemoteResource

To replace `ActiveResource` by providing a dynamic and customizable API interface for REST services.

## Installation

Add this line to your application's Gemfile:

```ruby
# Use this to fetch the gem from RubyGems.org
gem 'ddy_remote_resource', require: 'remote_resource'
```

## Usage

Simply include the `RemoteResource::Base` module in the class you want to enable for the REST services.

```ruby
class Post
  include RemoteResource::Base

  self.site       = 'https://www.example.com'
  self.collection = true # This option will become default in future versions

  attribute :title, String
  attribute :featured, Boolean
end
```

### Querying

#### Finder methods

To retrieve resources from the REST service, you can use the `.find`, `.find_by`, `.all` and `.where` class methods:

```ruby
# provide the `id` of the resource as argument
Post.find(12) #=> GET https://www.example.com/posts/12.json

# provide the conditions as argument
Post.find_by(title: 'Our awesome post') #=> GET https://www.example.com/posts.json?title=Our+awesome+post

# no arguments required
Post.all #=> GET https://www.example.com/posts.json

# provide the conditions as argument
Post.where(ids: [10, 11, 12]) #=> GET https://www.example.com/posts.json?ids[]=10&ids[]=11&ids[]=12
```

#### Persistence methods

To create or alter resources from the REST service, you can use the `.create` and `.destroy` class methods or the `#save`, `#update_attributes` and `#destroy` instance methods:

```ruby
# provide the attributes as argument
Post.create(title: 'Our awesome post', featured: true) #=> POST https://www.example.com/posts.json

# provide the attributes on the resource
# new resource
post          = Post.new
post.title    = 'Our awesome post'
post.featured = true
post.save #=> POST https://www.example.com/posts.json

# existing resource
post          = Post.new(id: 12)
post.title    = 'Our awesome post'
post.featured = true
post.save #=> PATCH https://www.example.com/posts/12.json

# provide the attributes as argument
post = Post.new(id: 12, title: 'Our post')
post.update_attributes(title: 'Our awesome post', featured: true) #=> PATCH https://www.example.com/posts/12.json

# provide the `id` of the resource as argument
Post.destroy(12) #=> DELETE https://www.example.com/posts/12.json

# provide the `id` on the resource
post = Post.new(id: 12)
post.destroy #=> DELETE https://www.example.com/posts/12.json
```

### Connection options
You can provide some options to alter the request. The options can be given as the first or second argument when making a request.

```ruby
connection_options = { root_element: :data, headers: { "X-Locale" => "nl" } }

Post.find(12, connection_options)

Post.all(connection_options)

Post.create({ title:'Our awesome post', featured: true }, connection_options)

post          = Post.new(id: 12)
post.title    = 'Our awesome post'
post.featured = true
post.save(connection_options)
```

#### REST methods

You can make custom requests by using the REST methods directly. The following REST methods are defined: the `.get`, `.put`, `.patch` and `.post` class methods or the `#get`, `#put`, `#patch` and `#post` instance methods.

```ruby
Post.post(title: 'Our awesome post', featured: true) #=> RemoteResource::Response
```

### Connection options

You can provide some connection options to alter the request. The options can be defined on serveral ways:
- On the `RemoteResource` enabled class
- In the `.with_connection_options` block
- Directly as the first or second argument when making a request.


#### URL options

There are several connection options that can alter the request URL. Normally the request URL is constructed using the `.site` and the relative class name of the `RemoteResource` enabled class. You can find this request URL by calling `.base_url` on the `RemoteResource` enabled class:

```ruby
Post.base_url #=> https://www.example.com/posts
```

We will use the `Post` class for these examples:

* `.site`: This sets the host which should be used to construct the `base_url`.
    * *Example:* `.site = 'https://api.myapp.com'`
    * `Post.base_url #=> https://api.myapp.com/posts`
* `.version`: This sets the API version for the path, after the `.site` and before the `.path_prefix` that is used to construct the `base_url`.
    * *Example:* `.version = '/api/v2'`
    * `Post.base_url #=> https://www.example.com/api/v2/posts`
* `.path_prefix`: This sets the prefix for the path, after the `.version` and before the `.collection_name` that is used to construct the `base_url`.
    * *Example:* `.path_prefix = '/registration'`
    * `Post.base_url #=> https://www.example.com/registration/posts`
* `.path_postfix`: This sets the postfix for the path, after the `.collection_name` that is used to construct the `base_url`.
    * *Example:* `.path_postfix = '/new'`
    * `Post.base_url #=> https://www.example.com/posts/new`
* `.collection`: This toggles the pluralization of the `collection_name` that is used to construct the `base_url`.
    * *Default:* `false`, but will be `true` in future versions
    * *Example:* `.collection = false`
    * `Post.base_url #=> https://www.example.com/post`
* `.collection_prefix`: This sets the prefix for the collection, before `collection_name` that is used to construct the `base_url`. The prefix variable has to be set via connection_options' key `collection_options`.
    * *Example:* `.collection_prefix = '/companies/:company_id'`
    * `Post.base_url #=> https://www.example.com/companies/:company_id/posts`
    * `Post.base_url(collection_options: { company_id: 2 }) #=> https://www.example.com/companies/2/posts`
* `.collection_name`: This sets the `collection_name` that is used to construct the `base_url`.
    * *Example:* `.collection_name = 'company'`
    * `Post.base_url #=> https://www.example.com/company`


#### Request options

Apart from the options which manipulate the request URL, there are also options to alter the request:

* `.default_headers`: This sets the default headers.
    * *Default:* `{ "Accept" => "application/json", "User-Agent" => "RemoteResource <version>" }`
    * *Example:* `.headers = { "User-Agent" => "My App" }`
    * `{ "User-Agent" => "My App" }`
* `.headers`: This sets the headers which are merged with the default headers.
    * *Default:* `{ "Accept" => "application/json", "User-Agent" => "RemoteResource <version>" }`
    * *Example:* `.headers = { "X-Locale" => "en" }`
    * `{ "Accept" => "application/json", "User-Agent" => "RemoteResource <version>", "X-Locale" => "en" }`


#### Body options

Some API wrap the resource within a specific element, we call this element the root element. When a root element is given as option the attributes in the request body will be wrapped in the element and the attributes of the response will be unwrapped from the element.

* `.root_element`: This sets the element in which the body is wrapped.
    * *Example:* `.root_element = :data`
    * `{"data":{"title":"My awesome post", "featured":true}}`

#### Using the `.with_connection_options` block

You can make your requests in a `.with_connection_options` block. All the requests in the block will use the passed in connection options.

```ruby
Post.with_connection_options(headers: { "X-Locale" => "en" }) do
  Post.find(12)
  Post.where({ featured: true }, { version: '/api/v2' })
  Post.all({ collection_prefix: '/companies/:company_id', collection_options: { company_id: 10 })
end
```

### Debug methods

The last request and response of the resource is set on the resource. You can use this to debug your implementation.

```ruby
post = Post.find(12)
post.last_request   #=> RemoteResource::Request
post.last_response  #=> RemoteResource::Response
```
