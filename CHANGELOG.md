# v1.0.2

- Dutch translation. (thanks @Vistaus)

- Quotes around process names and PIDs in texts.

# v1.0.1

- Fix the command tooltip text being unreadable on light color schemes: it now uses the Tooltip color set, so it follows the system theme. (#1)

- Fix RAM usage getting stuck at 0% while the popup is open: openSUSE's `top` prints the memory line in a format the parser could not read. (#2)

- Streamline CPU and RAM usage retrieval from `/proc/stat` and `/proc/meminfo` in every case, and use `top` only for the process list.

# v1.0.0

- Initial release.
