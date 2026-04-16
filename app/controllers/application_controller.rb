class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_nav_themes

  private

  def set_nav_themes
    @nav_themes = Theme.order(:id)
  end
end
