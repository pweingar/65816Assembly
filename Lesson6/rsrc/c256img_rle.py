#
# Convert an image for the C256
#

from PIL import Image
from optparse import OptionParser

class ImageConverter:

    def emit(self, file, color_count, color):
        """Emit a count and color for a run of pixels into the image area."""
        if self.count % 65536 == 0:
            address = 0x110000 + self.count
            file.write("\n* = ${:x}".format(address))
            if self.count == 0:
                file.write("\nIMG_START = *")
        if self.count % 16 == 0:
            file.write("\n.byte {}, {}".format(color_count, color))
        else:
            file.write(", {}, {}".format(color_count, color))
        self.count = self.count + 2

    def convert(self, input_file, pixmap_file, color_table):

        self.count = 0

        with Image.open(input_file) as im:
            with open(color_table, "w") as palette_file:
                palette_file.write("LUT_START\n")
                palette = im.getpalette()
                while palette:
                    r = palette.pop(0)
                    g = palette.pop(0)
                    b = palette.pop(0)
                    palette_file.write(".byte {}, {}, {}, 0\n".format(b, g, r))
                palette_file.write("\nLUT_END = *")

            line = ""

            pixel_count = 0
            last_pixel = -1
            with open(pixmap_file, "w") as image_file:
                (w, h) = im.size
                for v in range(0, h):
                    for u in range(0, w):
                        pixel = im.getpixel((u, v))
                        if pixel == last_pixel:
                            pixel_count = pixel_count + 1
                            if pixel_count == 255:
                                self.emit(image_file, pixel_count, pixel)
                                pixel_count = 0
                                last_pixel = -1
                        else:
                            if pixel_count > 0:
                                self.emit(image_file, pixel_count, last_pixel)
                            pixel_count = 1
                            last_pixel = pixel

                if pixel_count > 0:
                    self.emit(image_file, pixel_count, last_pixel)        

                image_file.write("\n.byte 0, 0")

parser = OptionParser()
parser.add_option("-i", "--input", dest="input", help="Source image file")
parser.add_option("-p", "--pixmap", dest="pixmap", default="src/rsrc/pixmap.s", help="Destination for pixel data.")
parser.add_option("-c", "--color-table", dest="color_table", default="src/rsrc/colors.s", help="Destination for color data.")

(options, args) = parser.parse_args()

ic = ImageConverter()
ic.convert(options.input, options.pixmap, options.color_table)