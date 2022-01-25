Dir.glob(File.expand_path('alma/*.rb', __dir__)).sort.each(&method(:require))
