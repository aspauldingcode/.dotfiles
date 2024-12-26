import frida
import sys
import os
from datetime import datetime

def on_message(message, data):
    if message['type'] == 'send':
        # Write to the file instead of printing
        with open(output_file, 'a') as f:
            f.write(f"{message['payload']}\n")
    elif message['type'] == 'error':
        with open(output_file, 'a') as f:
            f.write(f"Error: {message['description']}\n")

def main():
    # Get target process name from command line argument
    if len(sys.argv) != 2:
        print("Usage: python macos_classdump_frida.py <process_name>")
        sys.exit(1)

    process_name = sys.argv[1]
    
    # Define global output file path and create directory if needed
    global output_file
    output_dir = os.path.expanduser("~/classdump")
    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(output_dir, f"classdump_{process_name}.log")
    
    # Clear the file if it exists
    with open(output_file, 'w') as f:
        f.write(f"Class dump for {process_name}\n")
        f.write(f"Generated on: {datetime.now()}\n\n")

    # JavaScript code to perform the class dump
    script_code = """
    if (ObjC.available) {
        try {
            var classes = ObjC.classes;
            var classNames = Object.keys(classes);
            
            send("Found " + classNames.length + " classes");
            
            classNames.sort().forEach(function(className) {
                try {
                    send("\\n[*] " + className);
                    
                    var methods = classes[className].$ownMethods;
                    if (methods && methods.length > 0) {
                        send("\\tInstance Methods:");
                        methods.forEach(function(method) {
                            send("\\t\\t" + method);
                        });
                    }
                    
                    var classMethods = classes[className].$ownClassMethods;
                    if (classMethods && classMethods.length > 0) {
                        send("\\tClass Methods:");
                        classMethods.forEach(function(method) {
                            send("\\t\\t" + method);
                        });
                    }
                } catch(classErr) {
                    send("Error processing class " + className + ": " + classErr.message);
                }
            });
        } catch(err) {
            send("Exception: " + err.message);
        }
    } else {
        send("Objective-C Runtime is not available");
    }
    """

    try:
        # Attach to the target process
        session = frida.attach(process_name)
        
        # Create a script
        script = session.create_script(script_code)
        
        # Set up message handling
        script.on('message', on_message)
        
        # Load and run the script
        script.load()
        
        # Keep the script running
        print(f"[*] Dumping classes from {process_name}...")
        input("[!] Press Enter to stop...")
        
    except frida.ProcessNotFoundError:
        print(f"Error: Process '{process_name}' not found")
    except frida.ServerNotRunningError:
        print("Error: Frida server is not running")
    except Exception as e:
        print(f"Error: {str(e)}")
    finally:
        if 'session' in locals():
            session.detach()

if __name__ == "__main__":
    main()