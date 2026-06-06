#!/usr/bin/env python
import argparse
import logging
import sys
import xmlrpc.client

logging.basicConfig(format="%(levelname)s: %(message)s", level=logging.INFO)

####
## Pymol XML-RPC example
####
# import xmlrpc.client

# # Connect to the running PyMOL instance
# pymol = xmlrpc.client.ServerProxy(uri="http://localhost:9123/RPC2")

# # Example commands
# pymol.reinitialize()
# pymol.load("structure.pdb", "my_protein")
# pymol.hide("everything")
# pymol.show("cartoon")
# pymol.color("cyan", "chain A")

# # Example selection
# pymol.select("binding_pocket", "chain A and resi 50-60")
# pymol.show("sticks", "binding_pocket")
# pymol.color("yellow", "binding_pocket")
# pymol.zoom("binding_pocket")

# # To get information back from PyMOL
# view_matrix = pymol.get_view()
# print("Current view:", view_matrix)


def main():
    parser = argparse.ArgumentParser(description="Send PyMOL commands via XML-RPC.")
    parser.add_argument("commands", type=str, help="Semicolon-separated PyMOL commands to execute.")
    parser.add_argument("--host", type=str, default="localhost", help="XML-RPC server host (default: localhost)")
    parser.add_argument("--port", type=int, default=9123, help="XML-RPC server port (default: 9123)")
    
    args = parser.parse_args()
    
    uri = f"http://{args.host}:{args.port}/RPC2"
    
    try:
        pymol = xmlrpc.client.ServerProxy(uri)
        # Test connection (get_version returns a tuple like ('2.5.0', ...))
        try:
            pymol.get_version()
        except ConnectionRefusedError:
            logging.error(f"Connection refused. Is PyMOL XML-RPC server running on {uri}? (Start PyMOL with 'pymol -R')")
            sys.exit(1)
        except Exception as e:
            # Catch other errors but don't strictly fail on get_version in case it's restricted
            logging.warning(f"Could not verify PyMOL version: {e}. Proceeding anyway.")
            
    except Exception as e:
        logging.error(f"Failed to initialize XML-RPC client for {uri}: {e}")
        sys.exit(1)
        
    # Split the commands by semicolon and strip whitespace
    command_list = [cmd.strip() for cmd in args.commands.split(";") if cmd.strip()]
    
    for command in command_list:
        logging.info(f"Executing: {command}")
        try:
            # 'do' passes the raw command string to PyMOL's command parser
            result = pymol.do(command)
        except Exception as e:
            logging.error(f"Error executing command '{command}': {e}")
            sys.exit(1)

if __name__ == "__main__":
    main()
