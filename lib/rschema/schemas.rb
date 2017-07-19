# frozen_string_literal: true

Dir.glob(File.join(__dir__, 'schemas/**/*.rb')).each do |path|
  require path
end
