class WebScrappersController < ApplicationController
  def index
  	@data = WebScrapper.crawl_data(params[:web_scrapper][:search])
  end

  def new;end
end
