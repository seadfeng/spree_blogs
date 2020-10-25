require 'acts-as-taggable-on'

class Spree::Post < Spree::Base
  belongs_to :blog

  extend FriendlyId
  friendly_id :slug, use: [:slugged, :finders]

  acts_as_taggable_on :tags

  before_save :create_slug, :set_published_at

  validates :title, presence: true

  if Spree::Config[:blogs_use_action_text]
    has_rich_text :content_action_text
    has_rich_text :excerpt_action_text
    validates :content_action_text, presence: true
  else
    validates :content, presence: true
  end

  default_scope { order('published_at DESC') }
  scope :visible, -> { where visible: true }
  scope :recent, ->(max = 5) { visible.limit(max) }

  if Spree.user_class
    belongs_to :author, class_name: Spree.user_class.to_s, optional: true
  else
    belongs_to :author, optional: true
  end

  has_one :post_image, as: :viewable, dependent: :destroy, class_name: 'Spree::PostImage'
  accepts_nested_attributes_for :post_image, reject_if: :all_blank

  def post_excerpt(chars = 200)
    if excerpt.blank?
      "#{content[0...chars]}..."
    else
      excerpt
    end
  end

  def self.by_tag(tag_name)
    tagged_with(tag_name, on: :tags)
  end

  private

  def create_slug
    self.slug = if slug.blank?
                  title.to_url
                else
                  slug.to_url
                end
  end

  def set_published_at
    self.published_at = Time.now if published_at.blank?
  end
end
