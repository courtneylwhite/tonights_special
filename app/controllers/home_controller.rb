class HomeController < ApplicationController
  def index
    @authenticate_path = authenticate_path
  end
end
