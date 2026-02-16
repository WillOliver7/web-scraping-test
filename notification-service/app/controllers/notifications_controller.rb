class NotificationsController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  def update_progress
    ActionCable.server.broadcast("progress_channel_#{params[:task_id]}", {
      percentage: params[:percentage],
      status: params[:status]
    })
    head :ok
  end
end