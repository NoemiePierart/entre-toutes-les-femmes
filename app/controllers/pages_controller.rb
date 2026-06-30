class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    @newsletters = Newsletter.includes(posts: [ :theme, :rich_text_content ], cover_image_attachment: :blob).order(published_on: :desc).limit(4)
    @themes = Theme.where(archived: false).with_attached_image.order(:id)
    @hero_post = Post.includes(thumbnail_attachment: :blob).find(155)
  end

  def images
    redirect_to root_path unless current_user&.admin?
    @posts = Post.joins(:thumbnail_attachment)
                 .includes(:theme, :newsletter, thumbnail_attachment: :blob)
                 .order("newsletters.published_on DESC")
  end
end
