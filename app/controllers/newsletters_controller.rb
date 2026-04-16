class NewslettersController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @newsletters = Newsletter.order(published_on: :desc)
  end

  def show
    @newsletter = Newsletter.find_by!(number: params[:id])
    @posts = @newsletter.posts.includes(:theme).order("themes.name")
  end

end
