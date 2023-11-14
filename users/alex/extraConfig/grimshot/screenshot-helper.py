# Script to switch between screenshot window and screenshot area with grimshot linux by pressing spacebar.
from pynput import keyboard

def on_press(key):
    if key == keyboard.Key.esc:
        return False  # stop listener
    try:
        k = key.char  # single-char keys
    except:
        k = key.name  # other keys
    if k in ['1', '2', 'left', 'right']:  # keys of interest
        # self.keys.append(k)  # store it in global-like variable
        print('Key pressed: ' + k)
        return False  # stop listener; remove this if want more keys

listener = keyboard.Listener(on_press=on_press)
listener.start()  # start to listen on a separate thread
listener.join()  # remove if main thread is polling self.keys


# import keyboard
# import subprocess
#
# # List of commands to toggle between
# commands = [
#     "grimshot --notify save area",
#     "grimshot --notify save window"
# ]
# current_command_index = 0  # Index of the current command
#
# while True:
#     try:
#         if keyboard.is_pressed(' '):
#             # Wait for the spacebar to be released
#             while keyboard.is_pressed(' '):
#                 pass
#
#             # Execute the current command
#             subprocess.run(commands[current_command_index], shell=True)
#
#             # Toggle to the next command
#             current_command_index = (current_command_index + 1) % len(commands)
#     except KeyboardInterrupt:
#         break
#
