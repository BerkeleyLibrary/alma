Dir.glob(File.expand_path('lookup/*.rb', __dir__)).each(&method(:require))
