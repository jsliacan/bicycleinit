# BicycleInit

This repository contains the `bicycleinit.sh` script, which is used
for managing and configuring a bicycledata box. The script performs
the following tasks:

1. **Update the script**: Checks for updates to the repository and
   applies them.
2. **Device registration**: Registers the device with a server if it
   hasn't been registered before.
3. **Configuration update**: Retrieves and updates the configuration
   file (`config.json`) based on the device's registration
   information.

## Prerequisites

Before using the script, ensure that the following dependencies are
installed on your Raspberry Pi:

- **Git**: For fetching and pulling updates from the repository.
- **jq**: A lightweight command-line JSON processor for parsing JSON
  responses from the server.
- **curl**: For sending HTTP requests to the REST API.

You can install these dependencies using the following commands:

```bash
sudo apt-get update
sudo apt-get install git jq curl
```

## Usage

The `bicycleinit.sh` script accepts two optional arguments:

1. **Branch name**: The Git branch to check for updates. Defaults to
   `'main'`.
2. **Server REST API URL**: The base URL for the server's REST API.
   Defaults to `'https://bicycledata.ochel.se:80'`.

### Running the Script

To run the script with default parameters, use:

```bash
./bicycleinit.sh
```

To specify a different branch or API URL, you can pass them as arguments:

```bash
./bicycleinit.sh [branch_name] [server_rest_api_url]
```

### Example:

```bash
./bicycleinit.sh develop 127.0.0.1:5000
```

This command will check for updates on the `develop` branch and use the specified REST API URL.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
