require "rack-nocache"
use Rack::Nocache
app = Rack::Static.new nil, :urls => [""], :index =>'index.html', :root => ".."
run app
