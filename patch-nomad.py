media_dir = "/home/media/project-nomad" # Change to your preferred output directory
functions_to_skip = ['ensure_docker_installed']

#1. read downloaded install script into memory
nomad_file = open("install_nomad.sh").read()

nomad_file = nomad_file.replace('NOMAD_DIR="/opt/project-nomad"', f'NOMAD_DIR="{media_dir}"')

#2. Add remark in front of function call to skip that function
for function in functions_to_skip:
    nomad_file = nomad_file.replace(f'{function}\n', f'# {function}\n')

#3. save patched file
with open("patched_install_nomad.sh", "w") as file:
    file.write(nomad_file)
