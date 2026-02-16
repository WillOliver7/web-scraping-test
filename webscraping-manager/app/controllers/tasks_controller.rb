class TasksController < ApplicationController
  before_action :authorize_request

  def create
    task = Task.new(task_params)
    task.user_id = @current_user[:user_id]
    task.status = "pending"

    if task.save
      ScraperWorker.perform_async(task.id)
      render json: task, status: :created
    else
      render json: { errors: task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def index
    @tasks = Task.where(user_id: @current_user[:user_id])
                  .order(created_at: :desc)
                 .page(params[:page])
                 .per(10)
                 
    render json: {
      data: @tasks,
      meta: {
        current_page: @tasks.current_page,
        next_page: @tasks.next_page,
        prev_page: @tasks.prev_page,
        total_pages: @tasks.total_pages,
        total_count: @tasks.total_count
      }
    }
  end

  private

  def task_params
    params.require(:task).permit(:url)
  end
end