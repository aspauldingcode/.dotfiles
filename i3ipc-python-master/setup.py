from cx_Freeze import setup, Executable

# Dependencies are automatically detected, but it might need
# fine tuning.
build_options = {'packages': [], 'excludes': []}

import sys
base = 'Win32Service' if sys.platform=='win32' else None

executables = [
    Executable('~/.dotfiles/i3ipc-python-master/compiled/autotiling', base=base, target_name = 'autotiling')
]

setup(name='autotiling',
      version = '1.0',
      description = '',
      options = {'build_exe': build_options},
      executables = executables)
