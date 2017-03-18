arm-none-eabi-objcopy -O binary target target.bin
st-flash write target.bin 0x08000000