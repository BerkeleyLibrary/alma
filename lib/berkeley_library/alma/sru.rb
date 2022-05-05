Dir.glob(File.expand_path('sru/*.rb', __dir__)).sort.each(&method(:require))
