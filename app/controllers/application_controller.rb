class ApplicationController < ActionController::Base
  include Pagy::Backend
  before_action :authenticate_user!
  before_action :set_nav_themes

  private

  def set_nav_themes
    @nav_themes = Theme.where(archived: false).order(:id)
  end
end
