class ProgressChannel < ApplicationCable::Channel
  def subscribed
    stream_from "progress_channel_#{params[:task_id]}"
  end

  def unsubscribed
    stop_all_streams
  end
end
