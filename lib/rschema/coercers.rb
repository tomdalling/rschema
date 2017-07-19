# frozen_string_literal: true

Dir.glob(File.join(__dir__, 'coercers/**/*.rb')).each do |path|
  require path
end
