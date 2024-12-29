import serial
import time

# Initialize serial communication
ser = serial.Serial('COM3', 9600)

# Define two 3x3 matrices
matrix1 = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
]
matrix2 = [
    [9,  8,  7],
    [6,  5,  4],
    [3, 2, 1 ]
]

# Function to send a matrix
def send_matrix(matrix):
    for row in matrix:
        for element in row:
            ser.write(bytes([element]))  # Send each element as 1 byte
            print(f"Sent: {element}")
            time.sleep(0.1)  # Small delay for UART stability

# Send Matrix 1
print("Sending Matrix 1...")
send_matrix(matrix1)

# Wait for 2 seconds before sending the next matrix
time.sleep(1)

# Send Matrix 2
print("Sending Matrix 2...")
send_matrix(matrix2)

# Wait for the result from the FPGA
time.sleep(1)
print("Receiving result...")

# Read and print 9 elements (3x3 result matrix)
result_matrix = []
for i in range(9):
    result = ser.read(1)
    if result:
        value = ord(result)
        print(f"Received: {value}")
        result_matrix.append(value)

# Reshape the result into a 3x3 matrix for display
result_matrix = [
    result_matrix[0:3],
    result_matrix[3:6],
    result_matrix[6:9]
]
print("Result Matrix:")
for row in result_matrix:
    print(row)

ser.close()
