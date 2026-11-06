class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home, :about, :contact ]

  def home
    @themes = Theme.where(archived: false).with_attached_image.order(:id)
    @selections = @themes.index_with do |theme|
      theme.posts.daily_selection.includes(:theme, :rich_text_content).with_attached_thumbnail.limit(3).to_a
    end
    # Every theme gets an arch, but only themes with posts get a band
    @band_themes = @themes.select { |theme| @selections[theme].any? }
  end

  def about
  end

  def contact
  end

  def images
    redirect_to root_path unless current_user&.admin?
    @posts = Post.joins(:thumbnail_attachment)
                 .includes(:theme, :newsletter, thumbnail_attachment: :blob)
                 .order("newsletters.published_on DESC")
  end
end
