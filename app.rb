# -*- coding: utf-8 -*-
require 'sinatra'
require 'haml'
require 'open-uri'
require 'uri'
require 'sequel'
require 'nokogiri'
require 'logger'

CACHE_SEC = 600
DB = Sequel.sqlite('./db/icons.db', :loggers => [Logger.new($stdout)])

def user_data(screen_name)
  url = "http://twitter.com/users/show/#{screen_name}.xml"
  doc = Nokogiri::XML(open(url).read)
  return {
    :screen_name => doc.xpath('user/screen_name').inner_text,
    :icon_url    => doc.xpath('user/profile_image_url').inner_text,
    :updated_at  => Time.now.to_i
  }
end


get '/' do
  haml :index
end

get '/screen_name/:name' do
  begin
    name = params[:name]
    last_data = DB[:icons].first(:screen_name => name)

    if last_data.nil?
      data = user_data(name)
      DB[:icons].insert(data)
    elsif last_data[:updated_at] + CACHE_SEC < Time.now.to_i
      data = user_data(name)
      DB[:icons].filter(:screen_name => name).update(data)
    else
      data = last_data
    end

    if params[:size].nil?
      redirect(data[:icon_url])
    elsif params[:size] =~ /^orig/
      redirect(data[:icon_url].gsub(/_normal(\.[^.]+?)/, '\1'))
    else
      redirect(data[:icon_url].gsub(/normal(\.[^.]+?)/, params[:size] + '\1'))
    end

  rescue
    return 404
  end

end

not_found do
  redirect(request.url[0...request.url.rindex(request.path)] + '/error.png')
end

__END__

@@layout
!!!
%html
  %head
    %title twitter icon
  %body{:style => 'padding: 30px;'}
    = yield

@@index
%header
  %h1 twitter icon
  twitterのscreen_nameからiconのurlを取得します
%section
  %h3 つかいかた: http://#{request.env["HTTP_HOST"]}/screen_name/&lt;screen_name&gt?size=&lt;normal|bigger|mini|orig&gt;
  %h4 Example.
  - base = "http://#{request.env["HTTP_HOST"]}/screen_name/pokutuna"
  デフォルト(normal)
  %a{:href => "#{base}"} #{base}
  %img{:src => "#{base}"}
  %br

  - url = "#{base}?size=bigger"
  おおきめ
  %a{:href => "#{url}"} #{url}
  %img{:src => "#{url}"}
  %br

  - url = "#{base}?size=mini"
  ちいさめ
  %a{:href => "#{url}"} #{url}
  %img{:src => "#{url}"}
  %br

  - url = "#{base}?size=orig"
  オリジナルサイズ
  %a{:href => "#{url}"} #{url}
  %img{:src => "#{url}"}
  %br

%footer
  %a{:href => 'https://github.com/pokutuna/twittericon_proxy'} Github pokutuna/twittericon_proxy
