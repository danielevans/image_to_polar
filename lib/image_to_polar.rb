require 'rmagick'
require 'json'
# require 'image_to_polar/version'

module ImageToPolar
  class Translator
    attr_accessor :input_file_name
    attr_accessor :output_file_name
    attr_accessor :ranks
    attr_accessor :arc_segments

    def initialize options
      %i{input_file_name output_file_name ranks arc_segments}.each do |key|
        self.public_send(:"#{key}=", options.fetch(key))
      end
    end

    def translate!
      image = Array(Magick::Image.read(input_file_name)).first
      resulting_image = Array.new(ranks) { [0]*arc_segments }

      # get smarter about interpolation later.
      segment_width  = 10
      segment_height = 10

      center_column = (image.columns / 2.0).to_i
      center_row    = (image.rows    / 2.0).to_i
      max_radius    = [image.rows, image.columns].min / 2.0

      ranks.times do |rank|
        r = ((max_radius / ranks) * rank).to_i
        arc_segments.times do |i|
          theta = (2.0 * Math::PI / arc_segments) * i
          point_column = center_column + r * Math.cos(theta)
          point_row    = center_row    + r * Math.sin(theta)

          pixel = image.export_pixels point_column, point_row, 1, 1, "RGBA"

          # require at least 25% opacity to be visible. and an average whiteness of over 50%. Yes this is all bullshit.
          if pixel.last > 0xffff/4 && (pixel.first(3).reduce(&:+) / 3.0 > 0xffff / 4.0)
            resulting_image[rank][arc_segments - i] = 1 # reverses the image since theta is measured counter-clockwise by convention.
          end
        end
      end
      require 'pry'
      binding.pry
      output = JSON.generate(resulting_image)
      output.gsub!(/[\[\]]/, '[' => '{', ']' => '}')
      File.open output_file_name, 'w' do |f|
        f.write output
      end
    end
  end
end
