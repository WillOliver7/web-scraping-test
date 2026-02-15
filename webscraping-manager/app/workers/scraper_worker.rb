require 'httparty'
require 'nokogiri'

class ScraperWorker
  include Sidekiq::Worker
  # Opcional: configurar tentativas em caso de erro de rede
  sidekiq_options retry: 3

  def perform(task_id)
    task = Task.find_by(id: task_id)
    return unless task

    task.update(status: 'processing')

    begin
      # 1. Faz a requisição simples
      # Usamos um User-Agent comum para evitar bloqueios básicos, embora o Quotes não exija
      response = HTTParty.get(task.url, headers: {
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
      }, timeout: 10)

      if response.success?
        # 2. Faz o parsing do HTML
        doc = Nokogiri::HTML(response.body)

        # 3. Extrai dados específicos do quotes.toscrape.com
        # Vamos pegar o texto da primeira citação encontrada
        first_quote = doc.at_css('.quote .text')&.text&.strip
        author = doc.at_css('.quote .author')&.text&.strip

        if first_quote
          result_text = "#{author}: #{first_quote[0..50]}..."
          task.update(
            first_quote: first_quote,
            author: author,
            status: 'completed',
            last_error: nil
          )
        else
          # Fallback caso mude o seletor ou use outra URL
          title = doc.at_css('title')&.text&.strip
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
  end
end