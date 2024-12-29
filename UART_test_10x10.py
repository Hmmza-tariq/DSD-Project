import serial
import time
import numpy as np

# Initialize serial communication
ser = serial.Serial('COM3', 9600)

# Define two 10x10 matrices
matrix1 = np.array([
    [1, 2, 3, 1, 2, 3, 1, 2, 3, 1],
    [2, 3, 1, 2, 3, 1, 2, 3, 1, 2],
    [3, 1, 2, 3, 1, 2, 3, 1, 2, 3],
    [1, 2, 3, 1, 2, 3, 1, 2, 3, 1],
    [2, 3, 1, 2, 3, 1, 2, 3, 1, 2],
    [3, 1, 2, 3, 1, 2, 3, 1, 2, 3],
    [1, 2, 3, 1, 2, 3, 1, 2, 3, 1],
    [2, 3, 1, 2, 3, 1, 2, 3, 1, 2],
    [3, 1, 2, 3, 1, 2, 3, 1, 2, 3],
    [1, 2, 3, 1, 2, 3, 1, 2, 3, 1]
])

matrix2 = np.array([
    [1, 2, 3, 1, 2, 3, 1, 2, 3, 1],
    [2, 3, 1, 2, 3, 1, 2, 3, 1, 2],
    [3, 1, 2, 3, 1, 2, 3, 1, 2, 3],
    [1, 2, 3, 1, 2, 3, 1, 2, 3, 1],
    [2, 3, 1, 2, 3, 1, 2, 3, 1, 2],
    [3, 1, 2, 3, 1, 2, 3, 1, 2, 3],
    [1, 2, 3, 1, 2, 3, 1, 2, 3, 1],
    [2, 3, 1, 2, 3, 1, 2, 3, 1, 2],
    [3, 1, 2, 3, 1, 2, 3, 1, 2, 3],
    [1, 2, 3, 1, 2, 3, 1, 2, 3, 1]
])

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

# Read and print 100 elements (10x10 result matrix)
result_matrix = []
for i in range(100):
    result = ser.read(1)
    if result:
        value = ord(result)
        print(f"Received: {value}")
        result_matrix.append(value)

# Reshape the result into a 10x10 matrix for display
result_matrix = [
    result_matrix[i:i + 10] for i in range(0, len(result_matrix), 10)
]

# Display the result matrix
print("Result Matrix:")
for row in result_matrix:
    print(row)

# Close the serial connection
ser.close()
