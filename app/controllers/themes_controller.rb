class ThemesController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @theme = Theme.with_attached_image.all.find { |t| t.name.parameterize == params[:id] }
    raise ActiveRecord::RecordNotFound unless @theme
    @pagy, @posts = pagy(@theme.posts.includes(:newsletter, :rich_text_content, theme: { image_attachment: :blob }).with_attached_thumbnail.order("newsletters.published_on DESC"), limit: 20)
  end
end
