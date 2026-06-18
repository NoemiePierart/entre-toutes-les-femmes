class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    @newsletters = Newsletter.includes(posts: :theme, cover_image_attachment: :blob).order(published_on: :desc).limit(3)
    @themes = Theme.where(archived: false).order(:id)
  end

  def images
    redirect_to root_path unless current_user&.admin?
    @posts = Post.joins(:thumbnail_attachment)
                 .includes(:theme, :newsletter, thumbnail_attachment: :blob)
                 .order("newsletters.published_on DESC")
  end
end
