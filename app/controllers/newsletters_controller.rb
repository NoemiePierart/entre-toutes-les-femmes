class NewslettersController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @pagy, @newsletters = pagy(
      Newsletter.includes(posts: :theme, cover_image_attachment: :blob).order(published_on: :desc),
      limit: 12
    )
  end

  def show
    @newsletter = Newsletter.find_by!(number: params[:id])
    @posts = @newsletter.posts.includes(:theme).with_attached_thumbnail.order("themes.name")
  end

end
