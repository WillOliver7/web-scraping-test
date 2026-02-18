require 'httparty'
require 'nokogiri'

class ScraperWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3

  def perform(task_id)
    task = Task.find_by(id: task_id)
    return unless task

    task.update(status: 'processing')
    send_notification(task.id, 0, 'processing')

    begin      
      response = HTTParty.get(task.url, headers: {
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
      }, timeout: 10)

      if response.success?
        count = 0
        doc = Nokogiri::HTML(response.body)
        quote_elements = doc.css('.quote')
        total_quotes = quote_elements.size
        to_import = []

        if total_quotes == 0
          task.update(status: 'failed', last_error: "Nenhuma citação encontrada na página")
          send_notification(task.id, 100, 'failed')
          return
        end

        quote_elements.each_with_index do |quote_element, index|
          send_notification(task.id, ((index + 1) * 100.0 / total_quotes).to_i, 'processing')
          quote_text = quote_element.css('.text').text.strip
          author = quote_element.css('.author').text.strip
          to_import << Quote.new(task: task, user_id: task.user_id, content: quote_text, author: author)

          Quote.import(to_import, on_duplicate_key_update: [:content, :author]) if to_import.size >= 500
          to_import.clear if to_import.size >= 500
        end

        Quote.import(to_import, on_duplicate_key_update: [:content, :author]) if to_import.any?
        task.update(status: 'completed')
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