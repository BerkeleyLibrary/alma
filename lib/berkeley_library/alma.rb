Dir.glob(File.expand_path('alma/*.rb', __dir__)).each(&method(:require))
