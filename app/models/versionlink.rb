class Versionlink

  include Mongoid::Document
  include Mongoid::Timestamps

  field :language  , type: String
  field :prod_key  , type: String
  field :version_id, type: String
  field :link      , type: String
  field :name      , type: String
  field :manual    , type: Boolean, :default => false

  def as_json parameter
    {
      :name => self.name,
      :link => self.link,
      :created_at => self.created_at.strftime("%Y.%m.%d %I:%M %p"),
      :updated_at => self.updated_at.strftime("%Y.%m.%d %I:%M %p")
    }
  end

  def product
    product = nil
    if self.language
      product = Product.find_by_lang_key( self.language, self.prod_key )
    end
    if product.nil?
      product = Product.find_by_key( self.prod_key )
    end
    if !product.nil?
      product.version = self.version_id
    end
    product
  end

  def self.find_by( language, prod_key, link )
    Versionlink.where( language: language, prod_key: prod_key, link: link )[0]
  end

  def self.find_version_link(language, prod_key, version_id, link)
    Versionlink.where( language: language, prod_key: prod_key, version_id: version_id, link: link )
  end

  def self.create_versionlink language, prod_key, version_number, link, name
    return nil if link.nil? || link.empty?
    if link.match(/^http.*/).nil? && link.match(/^git.*/).nil?
      link = "http://#{link}"
    end
    versionlinks = Versionlink.find_version_link(language, prod_key, version_number, link)
    if versionlinks && !versionlinks.empty?
      Rails.logger.info "-- link exist already : #{prod_key} - #{version_number} - #{link} - #{name}"
      return nil
    end
    versionlink = Versionlink.new({:name => name, :link => link, :language => language,
      :prod_key => prod_key, :version_id => version_number })
    versionlink.save
  end

  def get_link
    return "http://#{self.link}" if self.link.match(/^www.*/) != nil
    return self.link
  end

end
