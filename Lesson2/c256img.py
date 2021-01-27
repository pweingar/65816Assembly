#
# Convert an image for the C256
#

from PIL import Image
from optparse import OptionParser

parser = OptionParser()
parser.add_option("-i", "--input", dest="input", help="Source image file")
parser.add_option("-p", "--pixmap", dest="pixmap", default="src/rsrc/pixmap.s", help="Destination for pixel data.")
parser.add_option("-c", "--color-table", dest="color_table", default="src/rsrc/colors.s", help="Destination for color data.")

(options, args) = parser.parse_args()

with Image.open(options.input) as im:
    with open(options.color_table, "w") as palette_file:
        palette_file.write("LUT_START\n")
        palette = im.getpalette()
        while palette:
            r = palette.pop(0)
            g = palette.pop(0)
            b = palette.pop(0)
            palette_file.write(".byte {}, {}, {}, 0\n".format(b, g, r))
        palette_file.write("\nLUT_END = *")


    count = 0
    line = ""

    with open(options.pixmap, "w") as image_file:
        (w, h) = im.size
        for v in range(0, h):
            for u in range(0, w):
                pixel = im.getpixel((u, v))
                if count % 65536 == 0:
                    address = 0x110000 + count
                    image_file.write("\n* = ${:x}".format(address))
                    if count == 0:
                        image_file.write("\nIMG_START = *")
                if count % 16 == 0:
                    image_file.write("\n.byte {}".format(pixel))
                else:
                    image_file.write(", {}".format(pixel))
                count = count + 1

        image_file.write("\nIMG_END = *")