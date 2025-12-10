1.1  **Initialize (First Time Only):**
    Run the setup command to mount your 5TB disk and set up Rust.

    ```bash
    ./setup-cfg01-vylabs-manage.sh setup
    ```

1.2.  **Launch:**
    Start your preferred mode. For example, for the "Teamwork" configuration we discussed:

    ```bash
    ./setup-cfg01-vylabs-manage.sh dual
    ```

    **Daily Operation:**

    > To focus deep on design: `./setup-cfg01-vylabs-manage.sh solo-architect`
    > To focus deep on code: `./setup-cfg01-vylabs-manage.sh solo-builder`
    > To stop everything: `./setup-cfg01-vylabs-manage.sh stop`

1.3.  **Connect (From your Local Machine):**
    Don't forget to run your SSH tunnel locally (as per your cheatsheet) to access these new ports:

    ```bash
    # Run this on your LAPTOP/DEV MACHINE
    autossh -M 0 -N \
      -L 30000:localhost:30000 \
      -L 30001:localhost:30001 \
      root@<YOUR_GPU_IP>
    ```


