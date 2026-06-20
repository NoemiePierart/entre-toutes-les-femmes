class ThemesController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @theme = Theme.with_attached_image.find(params[:id])
    @pagy, @posts = pagy(@theme.posts.includes(:newsletter, theme: { image_attachment: :blob }).with_attached_thumbnail.order("newsletters.published_on DESC"), limit: 20)
  end
end
