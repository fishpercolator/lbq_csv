require 'dm-core'
require 'csv'

DataMapper::Logger.new($stderr, :debug)
DataMapper.setup(:default, 'mysql://db/leedsbeer')

class Post
  include DataMapper::Resource
  storage_names[:default] = 'wp_posts'
  
  property :id, Serial
  property :post_title, String
  property :post_excerpt, String
  property :post_date, DateTime
  property :guid, String
  property :post_status, String
  property :post_type, String
  
  has n, :post_locations, child_key: ['object_id']
  has n, :locations, through: :post_locations
  has n, :metas
  has n, :post_term_taxonomies, child_key: ['object_id']
  has n, :term_taxonomies, through: :post_term_taxonomies
  
  def lat
    locations.first.lat
  end
  
  def lng
    locations.first.lng
  end
  
  def meta(n)
    metas.first(meta_key: n)&.meta_value
  end
  
  def address
    meta 'address'
  end
  
  def phone
    meta 'phone'
  end
  
  def website
    meta 'website'
  end
  
  def twitter
    meta 'twitter'
  end
  
  def thumbnail
    meta 'Thumbnail'
  end
  
  def stars
    raw = meta '_et_features_rating'
    # Has to be a nicer way than this!
    @stars ||= Hash[*%w{beer atmosphere amenities value}.zip(raw.scan /(?<=")[\d.]+(?=")/).flatten]
  end
  
  def category
    term_taxonomies.first(taxonomy: 'category').term.name
  end
  
  def tags
    term_taxonomies.all(taxonomy: 'post_tag').map {|t| t.term.name}
  end
  
end

class Location
  include DataMapper::Resource
  storage_names[:default] = 'wp_geo_mashup_locations'
  
  property :id, Serial
  property :lat, Float
  property :lng, Float
end

class PostLocation
  include DataMapper::Resource
  storage_names[:default] = 'wp_geo_mashup_location_relationships'
  
  belongs_to :post,     key: true, child_key: ['object_id']
  belongs_to :location, key: true, child_key: ['location_id']
end

class Meta
  include DataMapper::Resource
  storage_names[:default] = 'wp_postmeta'
  
  property :meta_id, Serial
  property :meta_key, String
  property :meta_value, String
  
  belongs_to :post, child_key: ['post_id']
end

class Term
  include DataMapper::Resource
  storage_names[:default] = 'wp_terms'
  
  property :term_id, Serial
  property :name, String
end

class TermTaxonomy
  include DataMapper::Resource
  storage_names[:default] = 'wp_term_taxonomy'

  property :term_taxonomy_id, Serial
  property :taxonomy, String
  
  belongs_to :term, child_key: ['term_id']
end

class PostTermTaxonomy
  include DataMapper::Resource
  storage_names[:default] = 'wp_term_relationships'
  
  belongs_to :post, key: true, child_key: ['object_id']
  belongs_to :term_taxonomy, key: true, child_key: ['term_taxonomy_id']
end

CSV.open('leedsbeerquest.csv', 'w', force_quotes: true, encoding: 'UTF-8') do |csv|
  csv << ['name', 'category', 'url', 'date', 'excerpt', 'thumbnail', 'lat', 'lng', 'address', 'phone', 'twitter', 'stars_beer', 'stars_atmosphere', 'stars_amenities', 'stars_value', 'tags']
  Post.all(post_type: 'post', post_status: 'publish', order: 'post_title').each do |post|
    csv << [
      post.post_title, post.category, post.guid, post.post_date, post.post_excerpt,
      post.thumbnail, post.lat, post.lng, post.address, post.phone, post.twitter,
      post.stars['beer'], post.stars['atmosphere'], post.stars['amenities'], post.stars['value'],
      post.tags.sort.join(',')
    ]
  end
end
