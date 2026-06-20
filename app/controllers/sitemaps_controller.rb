class SitemapsController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @newsletters = Newsletter.order(published_on: :desc)
    @themes = Theme.all
    @posts = Post.includes(:newsletter).joins(:newsletter).order("newsletters.published_on DESC")
    render layout: false
  end
end
