import socket

# Server configuration
HOST = '127.0.0.1'
PORT = 12345

# Create a socket object
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Bind the socket to a specific address and port
server_socket.bind((HOST, PORT))

# Listen for incoming connections
server_socket.listen(1)
print(f"Server listening on {HOST}:{PORT}")

try:
    while True:
        # Accept a connection from a client
        client_socket, client_address = server_socket.accept()
        print(f"Connection established with {client_address}")

        # Receive data from the client
        data = client_socket.recv(1024)
        message = data.decode()
        print(f"Received data: {message}")

        if message.lower() == "quit":
            print("Client requested termination. Closing server...")
            break

        # Send a response back to the client
        response = "Hello, client! Thanks for connecting."
        client_socket.sendall(response.encode())

        # Close the connection
        client_socket.close()

except KeyboardInterrupt:
    print("\nClosing server...")
    server_socket.close()
