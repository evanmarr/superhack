<img width="568" height="403" alt="demo-image" src="https://github.com/user-attachments/assets/61d09294-ffff-42bf-89f3-a4df4271d31d" />

    To install:
      Run this command in your linux terminal:
        $ sudo git clone https://github.com/evanmarr/superhack.git ~/.superhack/
      Then, run is command:
        $ cd && nano .bashrc
      Scroll to the bottom of the file, and enter this:
        ```
        alias s-hack='sudo bash ~/.superhack/main.sh'
        ```
      Press ^O, enter, then ^X to exit.
      Run this:
        $ source ~/.bashrc
      There! You're all set up!
    To run:
      Run this:
        $ s-hack
