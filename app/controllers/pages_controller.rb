class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    @newsletters = Newsletter.includes(posts: :theme).order(published_on: :desc).limit(3)
  end
end
