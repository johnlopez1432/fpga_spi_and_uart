from PIL import Image
from PIL import ImageFont


img = Image.new('1', (6*95, 10), color=0)
img_w, img_h = img.size
font = ImageFont.truetype('bpdots.squares-bold.otf', 10)
out = ""
for i in range(32,127):
  mask = font.getmask(f"{chr(i)}^", mode="1")
  # print(chr(i))
  w_o, h = mask.size
  w = w_o - 7
  bitmap = []
  for i, item in enumerate(mask):
    if (len(bitmap) < 60):
      if (i % w_o < w):
        if (item == 0):
          bitmap.append(0)
        else:
          bitmap.append(1)
        if (i % w_o == w-1):
          for _ in range(6-w):
            bitmap.append(0)
  while (h < 10):
    for _ in range(6):
      bitmap.append(0)
    h += 1
  res = int("".join(str(x) for x in bitmap), 2)
  out += hex(res)[2:].zfill(15) + "\n"
  # s = "  "
  # for j, x in enumerate(bitmap):
  #   if (x == 1):
  #     s += "#"
  #   else:
  #     s += "."
  #   if (j % 6 == 5):
  #     s += "\n  "
  # print(s)

with open("ascii.mem", "w") as f:
  f.write(out)
