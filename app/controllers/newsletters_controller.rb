class NewslettersController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @pagy, @newsletters = pagy(
      Newsletter.includes(posts: [ :theme, :rich_text_content ], cover_image_attachment: :blob).order(published_on: :desc),
      limit: 15
    )
  end

  def show
    @newsletter = Newsletter.includes(cover_image_attachment: :blob).find_by!(number: params[:id])
    @posts = @newsletter.posts.includes(:theme, :rich_text_content).with_attached_thumbnail.order("themes.name")
  end

end
