# NewBox
Powershell script to auto-install your favorite software packages on a new machine.

Download the NewBox_v2.ps1 file.
Optionally, download the Software.csv file.
Alternatively, create a new CSV file with a 'title' column and a 'package' column.  The 'title' column should contain the human-friendly name of the package you wish to install.  The 'package' column should contain the name of the chocolatey package.

As long as the script and the CSV file are kept in the same directory, the script will find the CSV when you run it and will install everything on the list.  It does NOT auto-restart the system, but will include any dependencies.
