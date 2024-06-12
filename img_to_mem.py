import sys
from PIL import Image

LENGTH = 160
WIDTH = 120

def resize(img: Image) -> Image:
  return img.resize((LENGTH,WIDTH))

def recolor(img: Image) -> list[tuple[int, int, int]]:
  img.convert("RGB")
  d = img.getdata()
  img_map = []
  new_image = []
  for item in d:
    # convert pixels from 24-bit true color to 16-bit high color
    r = (int)(item[0]/255 * 31)
    g = (int)(item[1]/255 * 63)
    b = (int)(item[2]/255 * 31)
    r_n = (int)(r/31 * 255)
    g_n = (int)(g/63 * 255)
    b_n = (int)(b/31 * 255)
    img_map.append((r,g,b))
    new_image.append((r_n, g_n, b_n, 255))

  img.putdata(new_image)
  img.show()

  return img_map

def create_mem(img_map: list[tuple[int, int, int]], file: str) -> None:
  out = ""
  for pixel in img_map:
    bin_str = bin(pixel[0])[2:].zfill(5) + bin(pixel[1])[2:].zfill(6) + bin(pixel[2])[2:].zfill(5)
    hex_str = hex(int(bin_str,2))[2:].zfill(4)
    out += hex_str + "\n"
  with open(file, "w") as f:
    f.write(out)


def main(params):
  NUM_PARAMS = 2 # Number of expected parameters
  if len(params) > NUM_PARAMS:
    print("This function takes a maximum of two arguments.")
    sys.exit(1)
  # Pad the list of parameters with `None` to meet the expected number
  if (len(params) == 0):
    params.append("image.png")
  if (len(params) < NUM_PARAMS):
    params.append("image.mem")

  img: Image = Image.open(params[0])
  img = resize(img)
  img_map = recolor(img)
  create_mem(img_map, params[1])

if __name__ == "__main__":
  # only pass parameters to main()
  main(sys.argv[1:])
