require 'httparty'
require 'nokogiri'

class ScraperWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3

  def perform(task_id)
    task = Task.find_by(id: task_id)
    return unless task

    task.update(status: 'processing')
    send_notification(task.id, 10, 'processing')
    sleep 1 

    begin
      send_notification(task.id, 30, 'processing')
      
      response = HTTParty.get(task.url, headers: {
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
      }, timeout: 10)

      if response.success?
        doc = Nokogiri::HTML(response.body)
        first_quote = doc.at_css('.quote .text')&.text&.strip
        author = doc.at_css('.quote .author')&.text&.strip

        send_notification(task.id, 90, 'processing')
        sleep 1

        if first_quote
          task.update(
            first_quote: first_quote,
            author: author,
            status: 'completed',
            last_error: nil
          )
        else
          task.update(status: 'completed')
        end
      else
        task.update(status: 'failed', last_error: "HTTP Error: #{response.code}")
      end

    rescue Net::OpenTimeout, Net::ReadTimeout
      task.update(status: 'failed', last_error: "Timeout na conexão")
    rescue => e
      task.update(status: 'failed', last_error: "Erro inesperado: #{e.message}")
    end

    send_notification(task.id, 100, task.status)
  end

  def send_notification(task_id, percentage, status)
    begin
      HTTParty.post("http://notification-service:3002/update_progress", body: {
        task_id: task_id,
        percentage: percentage,
        status: status
      }, timeout: 2)
    rescue => e
      Rails.logger.error "Falha ao enviar notificação: #{e.message}"
    end
  end
end