require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

helpers do

  def in_paragraphs(chapter)
    ch_id = 0
    chapter.split("\n\n").map do |paragraph|
      ch_id += 1
      "<p id=#{ch_id}>#{paragraph}</p>"
    end.join
  end

  def highlight(text, portion)
    text.gsub(portion, "<b>#{portion}</b>")
  end

end

before do
  @contents = File.readlines('data/toc.txt')
end

not_found do
  redirect "/"
end

def each_chapter
  @contents.each_with_index do |name, idx|
    number = idx + 1
    contents = File.read("data/chp#{number}.txt")
    yield(number, name, contents)
  end
end

def matching_chapters(query)
  results = []

  return results if !query || query.empty?

  each_chapter do |number, name, contents|
    if contents.include?(query)
      results << {
        name: name, 
        number: number,
        contents: contents
        }
    end
  end
  results
end

def matching_paragraphs(chapter_content, query)
  results = []

  in_paragraphs(chapter_content).split('<p id=').each do |prgrph|
    paragraph_num = prgrph.scan(/^\d{1,}/)[0]
    
    results += ["<p id=" + prgrph, paragraph_num] if prgrph.include?(query)
  end

  results
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end

def matching_paragraphs_with_corresponding_chapters(term)
  # returns hash: { chapter name, number & contents hash } => [paragraph & id pairs] } 

  results = Hash.new([])
  
  search_term = term
  matching_chapters(term).each do |chapter_hash|
    chapter_content = chapter_hash[:contents]
    results[chapter_hash] = matching_paragraphs(chapter_content, search_term)
  end

  results
end

get "/chapter/:number" do
  chapter_num = params[:number].to_i

  redirect "/" unless chapter_num.between?(1, @contents.length)

  chapter_name = @contents[chapter_num - 1]
  @title = "Chapter #{chapter_num}: #{chapter_name}"

  @chapter = File.read("data/chp#{chapter_num}.txt")
  
  erb :chapter
end

get "/search" do
  @matching_paragraphs = matching_paragraphs_with_corresponding_chapters(params[:query])
  
  erb :search
end
