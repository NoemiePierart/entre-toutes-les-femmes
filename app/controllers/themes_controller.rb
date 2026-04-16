class ThemesController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @theme = Theme.find(params[:id])
    @posts = @theme.posts.includes(:newsletter).order("newsletters.published_on DESC")
  end
end
