import socket

# Server configuration
HOST = '127.0.0.1'
PORT = 12345

while True:
    # Create a socket object
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    try:
        # Connect to the server
        client_socket.connect((HOST, PORT))
        print(f"Connected to server on {HOST}:{PORT}")

        # Get user input
        user_input = input("Enter a message (type 'quit' to exit): ")

        # Send user input to the server
        client_socket.sendall(user_input.encode())

        # Receive a response from the server
        data = client_socket.recv(1024)
        print(f"Received response: {data.decode()}")

        # Check if the user wants to exit
        if user_input.lower() == 'quit':
            print("Exiting client...")
            break

    finally:
        # Close the connection
        client_socket.close()
