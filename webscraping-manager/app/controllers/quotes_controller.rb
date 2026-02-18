class QuotesController < ApplicationController
  before_action :authorize_request

  def index
    @quotes = Quote.where(user_id: @current_user[:user_id])
                 .page(params[:page])
                 .per(5)

    render json: {
      data: @quotes,
      meta: {
        current_page: @quotes.current_page,
        next_page: @quotes.next_page,
        prev_page: @quotes.prev_page,
        total_pages: @quotes.total_pages,
        total_count: @quotes.total_count
      }
    }
  end
end