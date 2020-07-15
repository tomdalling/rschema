# frozen_string_literal: true

Dir.glob(File.join(__dir__, 'schemas/**/*.rb')).sort.each do |path|
  require path
end
