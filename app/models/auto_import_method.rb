class AutoImportMethod < ActiveRecord::Base
	IMPORT_METHODS = { :ofx => 1, :scrape => 2 }
end