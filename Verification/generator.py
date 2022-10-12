import numpy as np
import cv2
from PIL import Image


image = cv2.imread('./image.jpg',0) 
image = cv2.resize(image, (32, 31), interpolation=cv2.INTER_AREA) 

arr_res = np.array(image)
arr_odd = arr_res[::2]

ELA = np.zeros([15, 32])
for row in range(15):
    for col in range(32):
        if(col==0 or col==31):
            ELA[row][col] = int((int(arr_odd[row][col]) + int(arr_odd[row+1][col]))/2)
        else: 
            a = int(arr_odd[row][col-1])
            b = int(arr_odd[row][col])
            c = int(arr_odd[row][col+1])
            d = int(arr_odd[row+1][col-1])
            e = int(arr_odd[row+1][col])
            f = int(arr_odd[row+1][col+1])

            D1 = abs(a-f)
            D2 = abs(b-e)
            D3 = abs(c-d)

            if(D2 <= D1 and D2 <= D3):
                ELA[row][col] = int((int(arr_odd[row][col]) + int(arr_odd[row+1][col]))/2)
            elif(D1 <= D2 and D1 <= D3):
                ELA[row][col] = int((int(arr_odd[row][col-1]) + int(arr_odd[row+1][col+1]))/2)
            else:
                ELA[row][col] = int((int(arr_odd[row][col+1]) + int(arr_odd[row+1][col-1]))/2)

for row in range(15):
    for col in range(32):
        arr_res[2*row+1][col] = ELA[row][col]

np.savetxt('./img.dat', arr_odd, fmt="%d")
np.savetxt('./golden.dat', arr_res, fmt="%d")


file = open('./img.dat',"w")
for row in range(16):
    for col in range(32):
        file.write(hex(arr_odd[row][col])[2:])
        file.write('\r')
file.close()


file = open('./golden.dat',"w")
for row in range(31):
    for col in range(32):
        file.write(hex(arr_res[row][col])[2:])
        file.write('\r')
file.close()