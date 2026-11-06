require "test_helper"

class PostTest < ActiveSupport::TestCase
  setup do
    @theme = Theme.create!(name: "Mystère féminin")
    @newsletter = Newsletter.create!(number: 901, published_on: Date.new(2024, 5, 5))
    @user = User.create!(email: "autrice@example.com", password: "password123")
  end

  test "a heading that is all one quotation loses its quotes" do
    post = build_post("<h3>\"bienheureuse\"</h3><p>Marie dit alors…</p>")

    assert_equal "Bienheureuse", post.display_title
    assert_equal "Marie dit alors…", post.excerpt
  end

  test "quotes inside a heading become French guillemets" do
    post = build_post("<h3>Une sorte de \"prophétie\" immanente</h3><p>Texte</p>")

    assert_equal "Une sorte de « prophétie » immanente", post.display_title
  end

  test "entities in the heading come out as characters" do
    post = build_post("<h3>La vieillesse est-elle un naufrage ?&nbsp;</h3><p>Texte</p>")

    assert_equal "La vieillesse est-elle un naufrage ?", post.display_title
  end

  private

  def build_post(html)
    Post.create!(title: "Titre en base", content: html, theme: @theme, newsletter: @newsletter, user: @user)
  end
end
