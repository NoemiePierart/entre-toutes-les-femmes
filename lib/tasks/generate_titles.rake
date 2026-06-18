require "net/http"
require "json"

namespace :posts do
  desc "Generate titles for all posts without a title using Claude API"
  task generate_titles: :environment do
    api_key = ENV.fetch("ANTHROPIC_API_KEY") { abort "ANTHROPIC_API_KEY manquant" }

    posts = Post.where("title IS NULL OR title = '' OR title ~ '^.+ — Lettre [0-9]+'")
                .includes(:rich_text_content, :theme)
    puts "#{posts.count} posts sans titre à traiter..."

    posts.each do |post|
      content = post.content.to_plain_text.strip
      next if content.blank?

      theme_name = post.theme&.name || ""

      prompt = <<~PROMPT
        Tu es éditrice d'un blog catholique francophone pour femmes. Voici un article de la rubrique "#{theme_name}".

        Génère un titre court et percutant (5 à 8 mots maximum) pour cet article. Le titre peut être :
        - une citation courte extraite du texte
        - un titre nominal frappant
        - une question centrale

        Réponds UNIQUEMENT avec le titre, sans guillemets, sans ponctuation finale, sans explication.

        Contenu de l'article :
        #{content.first(2000)}
      PROMPT

      uri = URI("https://api.anthropic.com/v1/messages")
      req = Net::HTTP::Post.new(uri)
      req["x-api-key"] = api_key
      req["anthropic-version"] = "2023-06-01"
      req["content-type"] = "application/json"
      req.body = JSON.generate({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 60,
        messages: [{ role: "user", content: prompt }]
      })

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

      if res.is_a?(Net::HTTPSuccess)
        title = JSON.parse(res.body).dig("content", 0, "text")&.strip
        if title.present?
          post.update_columns(title: title)
          puts "  [#{post.id}] #{title}"
        else
          puts "  [#{post.id}] Réponse vide, ignoré"
        end
      else
        puts "  [#{post.id}] Erreur API #{res.code}: #{res.body}"
      end

      sleep 0.3
    end

    puts "\nTerminé."
  end
end
