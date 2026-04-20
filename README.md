# Showroom

A Ruby gem wrapping Shopify's public, unauthenticated JSON endpoints — no app, no token, no session required.

```ruby
Showroom.configure { |c| c.store = 'acme.myshopify.com' }

Showroom::Product.where(limit: 5).each { |p| puts "#{p.title} — #{p.variants.first.price}" }
Showroom::Product.find('my-bike').available?
Showroom::Product.all.first(100)
```

## Installation

```sh
gem install showroom
```

Or in your Gemfile:

```ruby
gem 'showroom'
```

## Configuration

### Single-store (module-level)

```ruby
Showroom.configure do |c|
  c.store            = 'acme.myshopify.com'   # required
  c.per_page         = 50                      # default, max 250
  c.pagination_depth = 50                      # max pages for .all / each_page
  c.timeout          = 30                      # seconds
  c.open_timeout     = 10                      # seconds
  c.user_agent       = 'MyApp/1.0'             # optional override
end
```

All options can also be set via environment variables:

| Variable                | Key                |
|-------------------------|--------------------|
| `SHOWROOM_STORE`        | `store`            |
| `SHOWROOM_USER_AGENT`   | `user_agent`       |
| `SHOWROOM_PER_PAGE`     | `per_page`         |
| `SHOWROOM_TIMEOUT`      | `timeout`          |
| `SHOWROOM_OPEN_TIMEOUT` | `open_timeout`     |

### Multi-store (per-client instances)

```ruby
acme     = Showroom::Client.new(store: 'acme.myshopify.com')
globo    = Showroom::Client.new(store: 'globo.myshopify.com')

acme.products(limit: 5).map(&:title)
globo.product('road-bike').price

# Models remember which client fetched them
product = acme.product('lorem-road-bike')
product.url  # => "https://acme.myshopify.com/products/lorem-road-bike"

# base_url is available on any client
acme.base_url  # => "https://acme.myshopify.com"
```

## Products

```ruby
# List (single page)
Showroom::Product.where(limit: 10, product_type: 'Road Bike')

# Single
product = Showroom::Product.find('lorem-road-bike')
product.title          # => "Lorem Road Bike"
product.handle         # => "lorem-road-bike"
product.vendor         # => "Lorem Cycles"
product.available?     # => true  (any variant in stock)
product.price          # => "749.00"  (lowest variant price)
product.price_range    # => "749.00–899.00"
product.prices         # => ["749.00", "899.00"]  (unique prices from all variants)
product.url            # => "https://acme.myshopify.com/products/lorem-road-bike"
product.featured_image # => #<Showroom::ProductImage ...>  (first image)
product.main_image     # => #<Showroom::ProductImage ...>  (image with position 1)

# Variants
product.variants.each do |v|
  puts "#{v.title}  #{v.price}  #{v.compare_at_price}  on_sale=#{v.on_sale?}  available=#{v.available?}"
end

# All pages — returns an Enumerator
Showroom::Product.all.each { |p| puts p.title }

# Explicit page iteration
Showroom::Product.each_page(limit: 250) do |batch, page|
  puts "Page #{page}: #{batch.size} products"
end
```

### Module-level shortcuts

```ruby
Showroom.products(limit: 5)      # => Array<Product>
Showroom.product('lorem-road-bike') # => Product
```

## Collections

```ruby
# List
Showroom::Collection.where(limit: 10)

# Single
collection = Showroom::Collection.find('lorem-helmets')
collection.title          # => "Lorem Helmets"
collection.handle         # => "lorem-helmets"
collection.products_count # => 12
collection.url            # => "https://acme.myshopify.com/collections/lorem-helmets"

# Products in a collection
collection.products(limit: 5).each { |p| puts p.title }
```

### Module-level shortcuts

```ruby
Showroom.collections(limit: 5)          # => Array<Collection>
Showroom.collection('lorem-helmets')    # => Collection
```

## Search

Showroom wraps Shopify's `/search/suggest.json` endpoint via `Showroom.search`.

```ruby
result = Showroom.search('road bike', types: [:product, :collection], limit: 5)
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `q` (first arg) | String | — | Search query |
| `types:` | Array\<Symbol\> | `[:product, :collection]` | Resource types to include |
| `limit:` | Integer | `per_page` config | Max results per type |

Available `types:` values: `:product`, `:collection`, `:page`, `:article`, `:query`.

### Accessing results

```ruby
result = Showroom.search('lorem', types: [:product, :collection, :page, :article, :query])

result.products     # => Array<Search::ProductSuggestion>
result.collections  # => Array<Search::CollectionSuggestion>
result.pages        # => Array<Search::PageSuggestion>
result.articles     # => Array<Search::ArticleSuggestion>
result.queries      # => Array<Search::QuerySuggestion>

result.products.first.title  # => "Lorem Road Bike"
result.queries.first.text    # => "lorem road bike"
```

### Loading full models

Product and collection suggestions expose a `#load` method that fetches the complete model record:

```ruby
suggestion = result.products.first
product = suggestion.load  # => Showroom::Product (full record, makes one HTTP request)

suggestion = result.collections.first
collection = suggestion.load  # => Showroom::Collection

# Page, article, and query suggestions do not support #load
result.pages.first.load  # => NoMethodError
```

## Error handling

```ruby
begin
  Showroom::Product.find('does-not-exist')
rescue Showroom::NotFound => e
  puts "404: #{e.message}"
rescue Showroom::TooManyRequests
  puts "Rate limited — back off and retry"
rescue Showroom::InvalidResponse
  puts "Store may be password-protected or blocking requests"
rescue Showroom::ConnectionError
  puts "Network error"
rescue Showroom::Error => e
  puts "Other Showroom error: #{e}"
end
```

### Error hierarchy

```
Showroom::Error
├── ConfigurationError     bad or missing store URL
├── ConnectionError        network failure, timeout
├── InvalidResponse        200 OK but body is HTML (password-protected store)
└── ResponseError          HTTP status >= 400
    ├── ClientError        4xx
    │   ├── BadRequest     400
    │   ├── NotFound       404
    │   ├── UnprocessableEntity  422
    │   └── TooManyRequests     429
    └── ServerError        5xx
```

## Custom middleware

```ruby
Showroom.configure do |c|
  c.store      = 'acme.myshopify.com'
  c.middleware = ->(conn) {
    conn.response :logger
  }
end
```

## Caveats

- **Password-protected stores** return `200 OK` with an HTML body. Showroom raises `InvalidResponse` in this case.
- **Rate limits** — Shopify's public endpoints allow roughly 2 req/s per IP. Showroom raises `TooManyRequests` (429) but does not retry automatically. Add your own back-off logic.
- **`/products.json` may be disabled** on some stores. You'll receive a `NotFound` or `ServerError`.
- **User-Agent** — some stores block the default Faraday UA. Showroom sets its own identifying header by default; override via `c.user_agent` if needed.
- **Search result ordering is not stable** — `/search/suggest.json` does not guarantee a consistent order across requests. Results with equal relevance scores may alternate non-deterministically. Do not rely on `result.products.first` being the same between calls.

## License

[GNU General Public License v3.0 or later](LICENSE).
