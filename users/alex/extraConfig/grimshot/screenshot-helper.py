
import subprocess

def command1():
    print("Select Area")
    subprocess.run(["grimshot", "--notify", "save", "area"])

def command2():
    print("Select Window")
    subprocess.run(["grimshot", "--notify", "save", "window"])

toggle = 1

# Open the named pipe (FIFO) for reading
with open('~/.dotfiles/users/alex/extraConfig/grimshot/fifo', 'r') as fifo:
    while True:
        input_char = fifo.read(1)
        if input_char == " ":
            if toggle == 1:
                command1()
                toggle = 2
            else:
                command2()
                toggle = 1
