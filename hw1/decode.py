with open('important_packet', 'rb') as f:
    raw_request = f.read()

header_offset = raw_request.rfind(b'\xff\xd8')
footer_offset = raw_request.rfind(b'\xff\xd9')
jpeg = raw_request[header_offset:footer_offset+2]

with open('flag.jpg', 'wb') as f:
    f.write(jpeg)